// ignore_for_file: unused_element, directives_ordering

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

import 'package:j3tunes/API/musify.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/services/playlist_download_service.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/playlist_image_picker.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/confirmation_dialog.dart';
import 'package:j3tunes/widgets/playlist_bar.dart';
import 'package:j3tunes/widgets/section_header.dart';
import 'package:j3tunes/services/youtube_service.dart';

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
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.library)),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: commonSingleChildScrollViewPadding,
              child: Column(
                children: <Widget>[
                  _buildUserPlaylistsSection(primaryColor),
                  if (!offlineMode.value)
                    _buildUserLikedPlaylistsSection(primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
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
  return ValueListenableBuilder(
    valueListenable: currentLikedPlaylistsLength,
    builder: (_, value, __) {
      // Always show the section if there are any liked playlists
      if (userLikedPlaylists.isEmpty) {
        return const SizedBox();
      }
      
      return Column(
        children: [
          SectionHeader(title: context.l10n!.likedPlaylists),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _loadLikedPlaylistsWithSongs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                logger.log('Error in liked playlists section: ${snapshot.error}', null, null);
                return Center(child: Text('Error loading playlists'));
              } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return _buildPlaylistListView(context, snapshot.data!);
              } else {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('No liked playlists found'),
                  ),
                );
              }
            },
          ),
        ],
      );
    },
  );
}

Future<List<Map<String, dynamic>>> _loadLikedPlaylistsWithSongs() async {
  final playlistsWithSongs = <Map<String, dynamic>>[];
  final yt = YoutubeService();
  
  // Process all liked playlists, not just a subset
  for (final rawPlaylist in userLikedPlaylists) {
    try {
      final playlist = safeMapConvert(rawPlaylist);
      
      // Ensure we have a valid ytid
      if (playlist['ytid'] == null || playlist['ytid'].toString().isEmpty) {
        logger.log('Skipping playlist with no ytid: ${playlist['title']}', null, null);
        continue;
      }
      
      // If playlist doesn't have songs, try to load them
      if (playlist['list'] == null || (playlist['list'] as List).isEmpty) {
        try {
          final songMaps = await yt.fetchPlaylistWithFallback(playlist['ytid']);
          final safeSongMaps = safeListConvert(songMaps);
          if (safeSongMaps.isNotEmpty) {
            playlist['list'] = safeSongMaps;
            // Update image if not present
            if (playlist['image'] == null || playlist['image'].toString().isEmpty) {
              playlist['image'] = safeSongMaps.first['image'] ?? 'assets/images/JTunes.png';
            }
            // Update title if not present
            if (playlist['title'] == null || playlist['title'].toString().isEmpty) {
              playlist['title'] = safeSongMaps.first['title'] ?? 'Liked Playlist';
            }
          } else {
            // Even if no songs, add the playlist with empty list
            playlist['list'] = <Map<String, dynamic>>[];
          }
        } catch (e) {
          logger.log('Error loading songs for playlist ${playlist['ytid']}: $e', null, null);
          playlist['list'] = <Map<String, dynamic>>[];
        }
      } else {
        // Ensure existing list is properly converted
        playlist['list'] = safeListConvert(playlist['list']);
      }
      
      // Always add the playlist, even if it has no songs
      playlistsWithSongs.add(playlist);
      
    } catch (e) {
      logger.log('Error processing liked playlist: $e', null, null);
      // Add playlist even if there's an error, but with empty list
      final playlist = safeMapConvert(rawPlaylist);
      playlist['list'] = <Map<String, dynamic>>[];
      if (playlist['ytid'] != null) {
        playlistsWithSongs.add(playlist);
      }
    }
  }
  
  logger.log('Loaded ${playlistsWithSongs.length} liked playlists for library', null, null);
  return playlistsWithSongs;
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

      // Get first song's image from playlist
      String? dynamicPlaylistImage = playlist['image'];

      // Check if playlist has songs and get first song's image
      final playlistSongs = safeListConvert(playlist['list']);
      if (playlistSongs.isNotEmpty) {
        final firstSong = playlistSongs.first;
        dynamicPlaylistImage = firstSong['artUri'] ??
            firstSong['image'] ??
            firstSong['highResImage'] ??
            playlist['image'];
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
              final activeButtonBackground = theme.colorScheme.surfaceContainer;
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
                            child: const Icon(FluentIcons.person_add_24_filled),
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
