// ignore_for_file: prefer_const_constructors

import 'package:j3tunes/widgets/shimmer_widgets.dart';
// ignore_for_file: directives_ordering, unused_field, prefer_final_fields

/*
 *     Copyright (C) 2025 Valeri Gokadze
 *
 *     J3Tunes is free software: you can redistribute it and/or modify
 *     it under the terms of the GNU General Public License as published by
 *     the Free Software Foundation, either version 3 of the License, or
 *     (at your option) any later version.
 *
 *     J3Tunes is distributed in the hope that it will be useful,
 *     but WITHOUT ANY WARRANTY; without even the implied warranty of
 *     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *     GNU General Public License for more details.
 *
 *     You should have received a copy of the GNU General Public License
 *     along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *
 *     For more information about J3Tunes, including how to contribute,
 *     please visit: https://github.com/gokadzev/J3Tunes
 */

import 'dart:math';

import 'package:j3tunes/API/musify.dart' as musify;
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/services/data_manager.dart' as data_manager;
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:j3tunes/services/playlist_download_service.dart';
import 'package:j3tunes/services/playlist_sharing.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/playlist_image_picker.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/playlist_cube.dart';
import 'package:j3tunes/widgets/playlist_header.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/spinner.dart';

class PlaylistPage extends StatefulWidget {
  const PlaylistPage({
    super.key,
    this.playlistId,
    this.playlistData,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.isArtist = false,
  });

  final String? playlistId;
  final dynamic playlistData;
  final IconData cubeIcon;
  final bool isArtist;

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  List<dynamic> _songsList = [];
  dynamic _playlist;

  bool _isLoading = true;
  bool _hasMore = true;
  final int _itemsPerPage = 20; // 35 se 20 kar do (less load)
  var _currentPage = 0;
  var _currentLastLoadedId = 0;

  // For like, recent, download, custom playlist
  ValueNotifier<bool> playlistLikeStatus = ValueNotifier(false);

  // Check if playlist is liked
  Future<void> checkPlaylistLikeStatus() async {
    final id = _playlist?['ytid'] ?? widget.playlistId;
    if (id != null) {
      final liked = await isPlaylistLiked(id);
      playlistLikeStatus.value = liked;
    }
  }

  // Update like status
  Future<void> updatePlaylistLikeStatus(String? playlistId, bool like) async {
    if (playlistId == null) return;
    if (like) {
      await likePlaylist(playlistId);
    } else {
      await unlikePlaylist(playlistId);
    }
  }

  // Custom playlists ValueNotifier
  ValueNotifier<List<Map>> userCustomPlaylists = ValueNotifier([]);

  Future<void> loadUserCustomPlaylists() async {
    final playlists = await getAllCustomPlaylists();
    userCustomPlaylists.value = playlists;
  }

  Future<void> addSongInCustomPlaylist(
    BuildContext context,
    String playlistId,
    dynamic song, {
    int? indexToInsert,
  }) async {
    await addSongToCustomPlaylist(playlistId, song);
    await loadUserCustomPlaylists();
    setState(() {});
  }

  Future<void> removeSongFromPlaylist(String playlistId, dynamic song) async {
    await removeSongFromCustomPlaylist(playlistId, song);
    await loadUserCustomPlaylists();
    setState(() {});
  }

  // Removed unused setActivePlaylist and duplicate playlistLikeStatus
  bool playlistOfflineStatus = false;

  @override
  void initState() {
    super.initState();
    _initializePlaylist();
    loadUserCustomPlaylists();
  }

  Future<void> _initializePlaylist() async {
    if (!mounted) return;
    try {
      if (widget.playlistData != null) {
        // Playlist data passed from library or search
        _playlist = Map<String, dynamic>.from(widget.playlistData);

        // Ensure the playlist has a proper list
        if (_playlist['list'] == null || (_playlist['list'] as List).isEmpty) {
          // Try to load songs if playlist doesn't have them
          if (_playlist['ytid'] != null && _playlist['ytid'].isNotEmpty) {
            try {
              final playlistInfo =
                  await getPlaylistInfoForWidget(_playlist['ytid']);
              if (playlistInfo != null && playlistInfo['list'] != null) {
                _playlist['list'] = playlistInfo['list'];
              }
            } catch (e) {
              logger.log('Error loading playlist songs: $e', null, null);
              _playlist['list'] = [];
            }
          } else {
            _playlist['list'] = [];
          }
        }
      } else if (widget.playlistId != null && widget.playlistId!.isNotEmpty) {
        // Fetch playlist by ID
        try {
          final playlistInfo =
              await getPlaylistInfoForWidget(widget.playlistId!);
          if (playlistInfo != null) {
            _playlist = playlistInfo;
          } else {
            _playlist = {
              'list': [],
              'title': 'Playlist Not Found',
              'ytid': widget.playlistId ?? '',
              'image': '',
            };
          }
        } catch (e) {
          logger.log('Error fetching playlist: $e', null, null);
          _playlist = {
            'list': [],
            'title': 'Error Loading Playlist',
            'ytid': widget.playlistId ?? '',
            'image': '',
          };
        }
      } else {
        _playlist = {
          'list': [],
          'title': 'Empty Playlist',
          'ytid': '',
          'image': '',
        };
      }

      // Ensure list is always initialized
      if (_playlist['list'] == null) {
        _playlist['list'] = [];
      }

      await checkPlaylistLikeStatus();

      if (mounted) {
        _songsList.clear();
        _currentPage = 0;
        _currentLastLoadedId = 0;
        _hasMore = (_playlist['list'] as List).isNotEmpty;
        _loadMore();
      }
    } catch (e) {
      logger.log('Error initializing playlist: $e', null, null);
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadMore() {
    _isLoading = true;
    fetch().then((List<dynamic> fetchedList) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          if (fetchedList.isEmpty) {
            _hasMore = false;
          } else {
            _songsList.addAll(fetchedList);
          }
        });
      }
    }).catchError((error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  Future<List<dynamic>> fetch() async {
    try {
      final list = <dynamic>[];
      if (_playlist == null || _playlist['list'] == null) {
        return list;
      }

      final playlistSongs = _playlist['list'] as List;
      final _count = playlistSongs.length;

      if (_currentLastLoadedId >= _count) {
        return list; // No more songs to load
      }

      final n = min(_itemsPerPage, _count - _currentLastLoadedId);

      for (var i = 0; i < n; i++) {
        if (_currentLastLoadedId < _count) {
          list.add(playlistSongs[_currentLastLoadedId]);
          _currentLastLoadedId++;
        }
      }

      _currentPage++;
      return list;
    } catch (e, stackTrace) {
      logger.log('Error fetching playlist songs:', e, stackTrace);
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              Navigator.pop(context, widget.playlistData == _playlist),
        ),
        actions: [
          if (_playlist != null &&
              _playlist['ytid'] != null &&
              _playlist['source'] != 'user-created') ...[_buildLikeButton()],
          const SizedBox(width: 10),
          if (_playlist != null) ...[
            _buildSyncButton(),
            const SizedBox(width: 10),
            _buildDownloadButton(),
            const SizedBox(width: 10),
            if (_playlist['source'] == 'user-created')
              IconButton(
                icon: const Icon(FluentIcons.share_24_regular),
                onPressed: () async {
                  final encodedPlaylist = PlaylistSharingService.encodePlaylist(
                    _playlist,
                  );

                  final url = 'J3Tunes://playlist/custom/$encodedPlaylist';
                  await Clipboard.setData(ClipboardData(text: url));
                },
              ),
            const SizedBox(width: 10),
          ],
          if (_playlist != null && _playlist['source'] == 'user-created') ...[
            _buildEditButton(),
            const SizedBox(width: 10),
          ],
        ],
      ),
      body: _playlist == null || _isLoading
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    PlaylistHeaderShimmer(),
                    SizedBox(height: 20),
                    PlaylistSongListShimmer(),
                  ],
                ),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: buildPlaylistHeader(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    child: buildSongActionsRow(),
                  ),
                ),
                SliverPadding(
                  padding: commonListViewBottmomPadding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (BuildContext context, int index) {
                        final isRemovable =
                            _playlist['source'] == 'user-created';
                        return _buildSongListItem(index, isRemovable);
                      },
                      childCount:
                          _hasMore ? _songsList.length + 1 : _songsList.length,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPlaylistImage() {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isLandscape = screenWidth > MediaQuery.sizeOf(context).height;
    // Use first song's image if available
    String? playlistImage = _playlist['image'];
    if (_playlist['list'] != null &&
        _playlist['list'] is List &&
        (_playlist['list'] as List).isNotEmpty) {
      final songs = _playlist['list'] as List;
      final randomSong = songs[Random().nextInt(songs.length)];
      playlistImage = randomSong['artUri'] ??
          randomSong['image'] ??
          randomSong['highResImage'] ??
          randomSong['lowResImage'] ??
          playlistImage;
    }
    final playlistForCube = Map<String, dynamic>.from(_playlist);
    playlistForCube['image'] = playlistImage;
    return PlaylistCube(
      playlistForCube,
      size: isLandscape ? 300 : screenWidth / 2.5,
      cubeIcon: widget.cubeIcon,
    );
  }

  Widget buildPlaylistHeader() {
    final _songsLength = _playlist['list'].length;

    return PlaylistHeader(
      _buildPlaylistImage(),
      _playlist['title'],
      _songsLength,
    );
  }

  Widget _buildLikeButton() {
    return ValueListenableBuilder<bool>(
      valueListenable: playlistLikeStatus,
      builder: (_, value, __) {
        return IconButton(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          icon: value
              ? const Icon(FluentIcons.heart_24_filled)
              : const Icon(FluentIcons.heart_24_regular),
          iconSize: 26,
          onPressed: () async {
            playlistLikeStatus.value = !playlistLikeStatus.value;
            await updatePlaylistLikeStatus(
              _playlist['ytid'] ?? widget.playlistId,
              playlistLikeStatus.value,
            );

            // Update the length notifier to trigger library and home refresh
            final likedIds = await getLikedPlaylists();
            currentLikedPlaylistsLength.value = likedIds.length;
          },
        );
      },
    );
  }

  Widget _buildSyncButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.arrow_sync_24_filled),
      iconSize: 26,
      onPressed: _handleSyncPlaylist,
    );
  }

  Widget _buildEditButton() {
    return IconButton(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      icon: const Icon(FluentIcons.edit_24_filled),
      iconSize: 26,
      onPressed: () => showDialog(
        context: context,
        builder: (BuildContext context) {
          String customPlaylistName = _playlist['title'];
          String? imageUrl = _playlist['image'];
          var imageBase64 = (imageUrl != null && imageUrl.startsWith('data:'))
              ? imageUrl
              : null;
          if (imageBase64 != null) imageUrl = null;

          return StatefulBuilder(
            builder: (context, dialogSetState) {
              Future<void> _pickImage() async {
                final result = await pickImage();
                if (result != null) {
                  dialogSetState(() {
                    imageBase64 = result;
                    imageUrl = null;
                  });
                }
              }

              Widget _imagePreview() {
                return buildImagePreview(
                  imageBase64: imageBase64,
                  imageUrl: imageUrl,
                );
              }

              return AlertDialog(
                content: SingleChildScrollView(
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 7),
                      TextField(
                        controller: TextEditingController(
                          text: customPlaylistName,
                        ),
                        decoration: InputDecoration(
                          labelText: context.l10n!.customPlaylistName,
                        ),
                        onChanged: (value) {
                          customPlaylistName = value;
                        },
                      ),
                      if (imageBase64 == null) ...[
                        const SizedBox(height: 7),
                        TextField(
                          controller: TextEditingController(text: imageUrl),
                          decoration: InputDecoration(
                            labelText: context.l10n!.customPlaylistImgUrl,
                          ),
                          onChanged: (value) {
                            imageUrl = value;
                            imageBase64 = null;
                            dialogSetState(() {});
                          },
                        ),
                      ],
                      const SizedBox(height: 7),
                      if (imageUrl == null) ...[
                        buildImagePickerRow(
                          context,
                          _pickImage,
                          imageBase64 != null,
                        ),
                        _imagePreview(),
                      ],
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(context.l10n!.update.toUpperCase()),
                    onPressed: () {
                      final index = userCustomPlaylists.value.indexOf(
                        widget.playlistData,
                      );

                      if (index != -1) {
                        final newPlaylist = {
                          'title': customPlaylistName,
                          'source': 'user-created',
                          if (imageBase64 != null)
                            'image': imageBase64
                          else if (imageUrl != null)
                            'image': imageUrl,
                          'list': widget.playlistData['list'],
                        };
                        final updatedPlaylists = List<Map>.from(
                          userCustomPlaylists.value,
                        );
                        updatedPlaylists[index] = newPlaylist;
                        data_manager.addOrUpdateData(
                          'user',
                          'customPlaylists',
                          userCustomPlaylists.value,
                        );
                        setState(() {
                          _playlist = newPlaylist;
                        });
                        showToast(context, context.l10n!.playlistUpdated);
                      }

                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDownloadButton() {
    final playlistId = widget.playlistId ?? _playlist['title'];

    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: offlinePlaylistService.offlinePlaylists,
      builder: (context, offlinePlaylists, _) {
        playlistOfflineStatus = offlinePlaylistService.isPlaylistDownloaded(
          playlistId,
        );

        if (playlistOfflineStatus) {
          return IconButton(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            icon: const Icon(FluentIcons.arrow_download_off_24_filled),
            iconSize: 26,
            onPressed: () => _showRemoveOfflineDialog(playlistId),
            tooltip: context.l10n!.removeOffline,
          );
        }

        return ValueListenableBuilder<DownloadProgress>(
          valueListenable: offlinePlaylistService.getProgressNotifier(
            playlistId,
          ),
          builder: (context, progress, _) {
            final isDownloading = offlinePlaylistService.isPlaylistDownloading(
              playlistId,
            );

            if (isDownloading) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress.progress,
                    strokeWidth: 2,
                    backgroundColor: Colors.grey.withValues(alpha: .3),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  IconButton(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    icon: const Icon(FluentIcons.dismiss_24_filled),
                    iconSize: 14,
                    onPressed: () => offlinePlaylistService.cancelDownload(
                      context,
                      playlistId,
                    ),
                    tooltip: context.l10n!.cancel,
                  ),
                ],
              );
            }

            return IconButton(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              icon: const Icon(FluentIcons.arrow_download_24_filled),
              iconSize: 26,
              onPressed: () =>
                  offlinePlaylistService.downloadPlaylist(context, _playlist),
              tooltip: context.l10n!.downloadPlaylist,
            );
          },
        );
      },
    );
  }

  void _showRemoveOfflineDialog(String playlistId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(context.l10n!.removeOfflinePlaylist),
          content: Text(context.l10n!.removeOfflinePlaylistConfirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n!.cancel.toUpperCase()),
            ),
            TextButton(
              onPressed: () {
                offlinePlaylistService.removeOfflinePlaylist(playlistId);
                Navigator.pop(context);
                showToast(context, context.l10n!.playlistRemovedFromOffline);
              },
              child: Text(context.l10n!.remove.toUpperCase()),
            ),
          ],
        );
      },
    );
  }

  void _handleSyncPlaylist() async {
    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });
    // Sync not needed for JioSaavn playlists (no remote update)
  }

  void _updateSongsListOnRemove(int indexOfRemovedSong) {
    final dynamic songToRemove = _songsList.elementAt(indexOfRemovedSong);
    showToastWithButton(
      context,
      context.l10n!.songRemoved,
      context.l10n!.undo.toUpperCase(),
      () {
        addSongInCustomPlaylist(
          context,
          _playlist['title'],
          songToRemove,
          indexToInsert: indexOfRemovedSong,
        );
        _songsList.insert(indexOfRemovedSong, songToRemove);
        setState(() {});
      },
    );

    setState(() {
      _songsList.removeAt(indexOfRemovedSong);
    });
  }

  Widget _buildSortSongActionButton() {
    return DropdownButton<String>(
      borderRadius: BorderRadius.circular(5),
      dropdownColor: Theme.of(context).colorScheme.secondaryContainer,
      underline: const SizedBox.shrink(),
      iconEnabledColor: Theme.of(context).colorScheme.primary,
      elevation: 0,
      iconSize: 25,
      icon: const Icon(FluentIcons.filter_16_filled),
      items: <String>[context.l10n!.name, context.l10n!.artist].map((
        String value,
      ) {
        return DropdownMenuItem<String>(value: value, child: Text(value));
      }).toList(),
      onChanged: (item) {
        setState(() {
          final playlist = _playlist['list'];

          void sortBy(String key) {
            playlist.sort((a, b) {
              final valueA = a[key].toString().toLowerCase();
              final valueB = b[key].toString().toLowerCase();
              return valueA.compareTo(valueB);
            });
          }

          if (item == context.l10n!.name) {
            sortBy('title');
          } else if (item == context.l10n!.artist) {
            sortBy('artist');
          }

          _playlist['list'] = playlist;

          // Reset pagination and reload
          _hasMore = true;
          _songsList.clear();
          _currentPage = 0;
          _currentLastLoadedId = 0;
          _loadMore();
        });
      },
    );
  }

  Widget buildSongActionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _buildSortSongActionButton(),
        const SizedBox(width: 10),
        ElevatedButton(
          onPressed: () {
            if (_playlist != null &&
                _playlist['list'] != null &&
                (_playlist['list'] as List).isNotEmpty) {
              audioHandler.playPlaylistSong(playlist: _playlist, songIndex: 0);
            }
          },
          style: ElevatedButton.styleFrom(
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
          child: const Icon(
            Icons.play_arrow,
            size: 30,
          ),
        ),
      ],
    );
  }

  Widget _buildSongListItem(int index, bool isRemovable) {
    if (index >= _songsList.length) {
      if (!_isLoading) {
        _loadMore();
      }
      return const Spinner();
    }

    final borderRadius = getItemBorderRadius(index, _songsList.length);
    // Ensure SongBar gets the image as 'lowResImage' for artwork
    final song = _songsList[index];
    final songWithImage =
        song is Map<String, dynamic> ? Map<String, dynamic>.from(song) : song;
    if (songWithImage is Map<String, dynamic> &&
        songWithImage['image'] != null) {
      songWithImage['lowResImage'] = songWithImage['image'];
    }
    return SongBar(
      songWithImage,
      true,
      onRemove: isRemovable
          ? () async {
              await removeSongFromPlaylist(
                _playlist['title'],
                _songsList[index],
              );
              _updateSongsListOnRemove(index);
            }
          : null,
      onPlay: () {
        audioHandler.playPlaylistSong(playlist: _playlist, songIndex: index);
      },
      isSongOffline: playlistOfflineStatus,
      borderRadius: borderRadius,
    );
  }
}
