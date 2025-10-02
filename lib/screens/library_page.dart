// ignore_for_file: unused_element, directives_ordering

import 'dart:math';
import 'package:j3tunes/API/musify.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:hive/hive.dart';
import 'package:j3tunes/services/data_manager.dart' hide createCustomPlaylist;
import 'package:j3tunes/services/playlist_download_service.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/playlist_image_picker.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/banner_ad_widget.dart';
import 'package:j3tunes/widgets/confirmation_dialog.dart';
import 'package:j3tunes/widgets/playlist_bar.dart';
import 'package:j3tunes/widgets/section_header.dart';
import 'package:j3tunes/services/youtube_service.dart';
import 'package:j3tunes/main.dart'; // For logger

// Helper to safely convert Map to Map<String, dynamic>
Map<String, dynamic> safeMapConvert(dynamic map) {
  if (map == null) return <String, dynamic>{};
  if (map is Map<String, dynamic>) return map;
  if (map is Map) {
    return Map<String, dynamic>.from(map);
  }
  return <String, dynamic>{};
}

// Helper to safely convert List to List<Map<String, dynamic>>
List<Map<String, dynamic>> safeListConvert(dynamic list) {
  if (list == null) return <Map<String, dynamic>>[];
  if (list is List<Map<String, dynamic>>) return list;
  if (list is List) {
    return list.map((item) => safeMapConvert(item)).toList();
  }
  return <Map<String, dynamic>>[];
}

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  _LibraryPageState createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final GlobalKey<__LikedPlaylistsSectionState> _likedPlaylistsSectionKey =
      GlobalKey<__LikedPlaylistsSectionState>();

  String? _getRandomPlaylistImage(List<dynamic> songs) {
    if (songs.isEmpty) return null;
    final randomSong = songs[Random().nextInt(songs.length)];
    final songMap = safeMapConvert(randomSong);
    return songMap['artUri'] as String? ??
        songMap['image'] as String? ??
        songMap['highResImage'] as String? ??
        songMap['lowResImage'] as String?;
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.library)),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: Theme.of(context).colorScheme.primary,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: commonSingleChildScrollViewPadding,
                  child: Column(
                    children: <Widget>[
                      _buildUserPlaylistsSection(primaryColor),
                      if (!offlineMode.value)
                        _buildUserLikedPlaylistsSection(primaryColor),
                    const RepaintBoundary(
                        child: BannerAdWidget(),
                      ),    
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    logger.log('Refreshing Library...', null, null);

    // This will trigger a rebuild for any FutureBuilders, like for user-added YouTube playlists.
    setState(() {
      // This empty setState call is enough to make FutureBuilders rebuild.
    });

    // Refresh custom playlists from storage
    final customPlaylists = await getAllCustomPlaylists();
    userCustomPlaylists.value = customPlaylists;

    // Refresh offline playlists from storage
    offlinePlaylistService.offlinePlaylists.value =
        Hive.box('userNoBackup').get('offlinePlaylists', defaultValue: []);

    // Refresh liked playlists by calling the child's method
    _likedPlaylistsSectionKey.currentState?.refreshPlaylists();

    // A small delay to give feedback to the user that refresh happened
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Widget _buildUserPlaylistsSection(Color primaryColor) {
    final isUserPlaylistsEmpty =
        userPlaylists.value.isEmpty && userCustomPlaylists.value.isEmpty;
    return Column(
      children: [
        if (!offlineMode.value) ...[
          SectionHeader(
            title: context.l10n!.customPlaylists,
            actionButton: IconButton(
              padding: const EdgeInsets.only(right: 5),
              onPressed: _showAddPlaylistDialog,
              icon: Icon(FluentIcons.add_24_filled, color: primaryColor),
            ),
          ),
          PlaylistBar(
            context.l10n!.recentlyPlayed,
            onPressed: () =>
                NavigationManager.router.go('/library/userSongs/recents'),
            cubeIcon: FluentIcons.history_24_filled,
            borderRadius: commonCustomBarRadiusFirst,
            showBuildActions: false,
          ),
          PlaylistBar(
            context.l10n!.likedSongs,
            onPressed: () =>
                NavigationManager.router.go('/library/userSongs/liked'),
            cubeIcon: FluentIcons.music_note_2_24_regular,
            showBuildActions: false,
          ),
          PlaylistBar(
            context.l10n!.offlineSongs,
            onPressed: () =>
                NavigationManager.router.go('/library/userSongs/offline'),
            cubeIcon: FluentIcons.arrow_download_24_filled,
            borderRadius: isUserPlaylistsEmpty
                ? commonCustomBarRadiusLast
                : BorderRadius.zero,
            showBuildActions: false,
          ),
          ValueListenableBuilder<List>(
            valueListenable: userCustomPlaylists,
            builder: (context, playlists, _) {
              if (playlists.isEmpty) {
                return const SizedBox();
              }
              return _buildPlaylistListView(context, playlists);
            },
          ),
        ],
        _buildOfflinePlaylistsSection(),
        if (!offlineMode.value)
          ValueListenableBuilder<List>(
            valueListenable: userPlaylists,
            builder: (context, playlists, _) {
              if (userPlaylists.value.isEmpty) {
                return const SizedBox();
              }
              return Column(
                children: [
                  SectionHeader(
                    title: context.l10n!.addedPlaylists,
                    actionButton: IconButton(
                      padding: const EdgeInsets.only(right: 5),
                      onPressed: _showAddPlaylistDialog,
                      icon: Icon(
                        FluentIcons.add_24_filled,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  FutureBuilder(
                    future: getUserPlaylists(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      } else if (snapshot.hasData &&
                          snapshot.data!.isNotEmpty) {
                        return _buildPlaylistListView(context, snapshot.data!);
                      } else {
                        return const SizedBox();
                      }
                    },
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildUserLikedPlaylistsSection(Color primaryColor) {
    return _LikedPlaylistsSection(key: _likedPlaylistsSectionKey);
  }

  Widget _buildOfflinePlaylistsSection() {
    return ValueListenableBuilder<List<dynamic>>(
      valueListenable: offlinePlaylistService.offlinePlaylists,
      builder: (context, offlinePlaylists, _) {
        if (offlinePlaylists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SectionHeader(title: context.l10n!.offlinePlaylists),
            _buildPlaylistListView(
              context,
              offlinePlaylists,
              isOfflinePlaylists: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildAlbumsSection() {
    return FutureBuilder<List<dynamic>>(
      future: getAlbumsFromDatabase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return _buildPlaylistListView(context, snapshot.data!);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildPlaylistListView(
    BuildContext context,
    List playlists, {
    bool isOfflinePlaylists = false,
  }) {
    if (playlists.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No playlists available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      padding: commonListViewBottmomPadding,
      itemBuilder: (BuildContext context, index) {
        final rawPlaylist = playlists[index];
        final playlist = safeMapConvert(rawPlaylist);
        final borderRadius = getItemBorderRadius(index, playlists.length);

        // Get a random song's image from the playlist
        String? dynamicPlaylistImage = playlist['image'];

        // Check if playlist has songs and get a random song's image
        final playlistSongs = safeListConvert(playlist['list']);
        if (playlistSongs.isNotEmpty) {
          dynamicPlaylistImage =
              _getRandomPlaylistImage(playlistSongs) ?? playlist['image'];
        }

        return PlaylistBar(
          key: ValueKey('${playlist['ytid']}_$index'), // More unique key
          playlist['title'] ?? 'Unknown Playlist',
          playlistId: playlist['ytid'],
          playlistArtwork: dynamicPlaylistImage,
          isAlbum: playlist['isAlbum'] ?? false,
          playlistData: playlist,
          onDelete: playlist['source'] == 'user-created' ||
                  playlist['source'] == 'user-youtube'
              ? () => _showRemovePlaylistDialog(playlist)
              : null,
          borderRadius: borderRadius,
        );
      },
    );
  }

  void _showAddPlaylistDialog() => showDialog(
        context: context,
        builder: (BuildContext context) {
          var id = '';
          var customPlaylistName = '';
          var isYouTubeMode = true;
          String? imageUrl;
          String? imageBase64;

          return StatefulBuilder(
            builder: (context, dialogSetState) {
              final theme = Theme.of(context);
              final activeButtonBackground =
                  theme.colorScheme.surfaceContainer;
              final inactiveButtonBackground =
                  theme.colorScheme.secondaryContainer;
              final dialogBackgroundColor = theme.dialogTheme.backgroundColor;

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
                backgroundColor: dialogBackgroundColor,
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              dialogSetState(() {
                                isYouTubeMode = true;
                                id = '';
                                customPlaylistName = '';
                                imageUrl = null;
                                imageBase64 = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isYouTubeMode
                                  ? inactiveButtonBackground
                                  : activeButtonBackground,
                            ),
                            child: const Icon(FluentIcons.globe_add_24_filled),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              dialogSetState(() {
                                isYouTubeMode = false;
                                id = '';
                                customPlaylistName = '';
                                imageUrl = null;
                                imageBase64 = null;
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isYouTubeMode
                                  ? activeButtonBackground
                                  : inactiveButtonBackground,
                            ),
                            child:
                                const Icon(FluentIcons.person_add_24_filled),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (isYouTubeMode)
                        TextField(
                          decoration: InputDecoration(
                            labelText: context.l10n!.youtubePlaylistLinkOrId,
                          ),
                          onChanged: (value) {
                            id = value;
                          },
                        )
                      else ...[
                        TextField(
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
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text(context.l10n!.add.toUpperCase()),
                    onPressed: () async {
                      if (isYouTubeMode && id.isNotEmpty) {
                        final result = await addUserPlaylist(id, context);
                        showToast(context, result);
                        // Refresh the liked playlists to show in library
                        setState(() {});
                      } else if (!isYouTubeMode &&
                          customPlaylistName.isNotEmpty) {
                        showToast(
                          context,
                          createCustomPlaylist(
                            customPlaylistName,
                            imageBase64 ?? imageUrl,
                            context,
                          ),
                        );
                      } else {
                        showToast(
                          context,
                          '${context.l10n!.provideIdOrNameError}.',
                        );
                      }

                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          );
        },
      );

  void _showRemovePlaylistDialog(Map<String, dynamic> playlist) => showDialog(
        context: context,
        builder: (BuildContext context) {
          return ConfirmationDialog(
            confirmationMessage: context.l10n!.removePlaylistQuestion,
            submitMessage: context.l10n!.remove,
            onCancel: () {
              Navigator.of(context).pop();
            },
            onSubmit: () {
              Navigator.of(context).pop();

              if (playlist['ytid'] == null &&
                  playlist['source'] == 'user-created') {
                removeUserCustomPlaylist(playlist);
              } else {
                removeUserPlaylist(playlist['ytid']);
              }
              // Refresh the page to update the UI
              setState(() {});
            },
          );
        },
      );
}

class _LikedPlaylistsSection extends StatefulWidget {
  const _LikedPlaylistsSection({Key? key}) : super(key: key);

  @override
  __LikedPlaylistsSectionState createState() => __LikedPlaylistsSectionState();
}

class __LikedPlaylistsSectionState extends State<_LikedPlaylistsSection> {
  late Future<List<Map<String, dynamic>>> _likedPlaylistsFuture;

  @override
  void initState() {
    super.initState();
    _likedPlaylistsFuture = _loadLikedPlaylistsWithSongs();
  }

  void refreshPlaylists() {
    setState(() {
      _likedPlaylistsFuture = _loadLikedPlaylistsWithSongs();
    });
  }

  Future<List<Map<String, dynamic>>> _loadLikedPlaylistsWithSongs() async {
    final playlistsWithSongs = <Map<String, dynamic>>[];
    final likedIds = await getLikedPlaylists();

    for (final id in likedIds) {
      try {
        final playlistData = await getPlaylistInfoForWidget(id);
        if (playlistData != null) {
          playlistsWithSongs.add(Map<String, dynamic>.from(playlistData));
        }
      } catch (e) {
        logger.log(
          'Error loading liked playlist $id for library: $e',
          null,
          null,
        );
      }
    }

    logger.log(
        'Loaded ${playlistsWithSongs.length} liked playlists for library',
        null,
        null);
    return playlistsWithSongs;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _likedPlaylistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Don't show anything while loading, to avoid layout jumps.
          // A shimmer could be placed here if desired.
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          logger.log(
            'Error in liked playlists section: ${snapshot.error}',
            null,
            null,
          );
          // Don't show an error, just hide the section.
          return const SizedBox.shrink();
        }

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          return Column(
            children: [
              SectionHeader(title: context.l10n!.likedPlaylists),
              (context.findAncestorStateOfType<_LibraryPageState>()!)
                  ._buildPlaylistListView(context, snapshot.data!),
            ],
          );
        }

        // If there's no data or the list is empty, show nothing.
        return const SizedBox.shrink();
      },
    );
  }
}
