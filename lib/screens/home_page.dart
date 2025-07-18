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
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/playlist_page.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/playlist_cube.dart';
import 'package:j3tunes/widgets/section_header.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/spinner.dart';
import 'package:j3tunes/widgets/user_profile_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;
    
    return Scaffold(
      appBar: AppBar(title: const Text('JTunes')), // App name change kar diya
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        physics: const BouncingScrollPhysics(), // Smooth scrolling
        child: Column(
          children: [
            // Cache karo widgets
            const RepaintBoundary(child: UserProfileCard(showGreeting: true)),
            const SizedBox(height: 8),
            
            RepaintBoundary(child: _buildSuggestedPlaylists(playlistHeight)),
            RepaintBoundary(child: _buildSuggestedPlaylists(playlistHeight, showOnlyLiked: true)),
            RepaintBoundary(child: _buildRecommendedSongsSection(playlistHeight)),
            RepaintBoundary(child: _buildAlbumsSection(playlistHeight)),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(padding: EdgeInsets.all(35), child: Spinner()),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Text(
        '${context.l10n!.error}!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    final sectionTitle = showOnlyLiked
        ? context.l10n!.backToFavorites
        : context.l10n!.suggestedPlaylists;

    // Reduce height for showOnlyLiked section
    final adjustedHeight = showOnlyLiked
        ? playlistHeight * 0.6 // 40% smaller height for favorites
        : playlistHeight;

    return FutureBuilder<List<dynamic>>(
      future: getPlaylists(
        playlistsNum: recommendedCubesNumber,
        onlyLiked: showOnlyLiked,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildSuggestedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _buildErrorWidget(context);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final playlists = snapshot.data ?? [];
        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        return Column(
          children: [
            SectionHeader(title: sectionTitle),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: adjustedHeight),
              child: isLargeScreen
                  ? _buildHorizontalList(
                      playlists,
                      itemsNumber,
                      adjustedHeight,
                      showOnlyLiked: showOnlyLiked, // Pass the flag
                    )
                  : _buildCarouselView(
                      playlists,
                      itemsNumber,
                      adjustedHeight,
                      showOnlyLiked: showOnlyLiked, // Pass the flag
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalList(
    List<dynamic> playlists,
    int itemCount,
    double height, {
    bool showOnlyLiked = false,
  }) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(), // Normal smooth scroll
      padding: EdgeInsets.symmetric(
        horizontal: showOnlyLiked ? 12 : 8, // Tighter padding for favorites
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index];

        // Get first song's image from playlist for favorites
        String? dynamicPlaylistImage = playlist['image'];
        if (playlist['list'] != null && playlist['list'].isNotEmpty) {
          final firstSong = playlist['list'][0];
          dynamicPlaylistImage = firstSong['artUri'] ??
              firstSong['image'] ??
              firstSong['highResImage'] ??
              playlist['image'];
        }

        // Create modified playlist with dynamic image
        final modifiedPlaylist = Map<String, dynamic>.from(playlist);
        modifiedPlaylist['image'] = dynamicPlaylistImage;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showOnlyLiked ? 4 : 8, // Smaller spacing for favorites
          ),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    PlaylistPage(playlistId: playlist['ytid']),
              ),
            ),
            child: PlaylistCube(modifiedPlaylist, size: height),
          ),
        );
      },
    );
  }

  Widget _buildCarouselView(
    List<dynamic> playlists,
    int itemCount,
    double height, {
    bool showOnlyLiked = false,
  }) {
    // For favorites section, use regular ListView instead of CarouselView
    if (showOnlyLiked) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final playlist = playlists[index];

          String? dynamicPlaylistImage = playlist['image'];
          if (playlist['list'] != null && playlist['list'].isNotEmpty) {
            final firstSong = playlist['list'][0];
            dynamicPlaylistImage = firstSong['artUri'] ??
                firstSong['image'] ??
                firstSong['highResImage'] ??
                playlist['image'];
          }

          final modifiedPlaylist = Map<String, dynamic>.from(playlist);
          modifiedPlaylist['image'] = dynamicPlaylistImage;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistPage(playlistId: playlist['ytid']),
                ),
              ),
              child: PlaylistCube(modifiedPlaylist, size: height),
            ),
          );
        },
      );
    }

    // Default CarouselView for suggested playlists
    return CarouselView.weighted(
      flexWeights: const <int>[3, 2, 1],
      itemSnapping: true,
      onTap: (index) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PlaylistPage(playlistId: playlists[index]['ytid']),
        ),
      ),
      children: List.generate(itemCount, (index) {
        final playlist = playlists[index];

        String? dynamicPlaylistImage = playlist['image'];
        if (playlist['list'] != null && playlist['list'].isNotEmpty) {
          final firstSong = playlist['list'][0];
          dynamicPlaylistImage = firstSong['artUri'] ??
              firstSong['image'] ??
              firstSong['highResImage'] ??
              playlist['image'];
        }

        final modifiedPlaylist = Map<String, dynamic>.from(playlist);
        modifiedPlaylist['image'] = dynamicPlaylistImage;

        return PlaylistCube(modifiedPlaylist, size: height * 2);
      }),
    );
  }

  Widget _buildRecommendedSongsSection(double playlistHeight) {
    return ValueListenableBuilder<bool>(
      valueListenable: defaultRecommendations,
      builder: (_, recommendations, __) {
        return FutureBuilder<dynamic>(
          future: getRecommendedSongs(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            if (snapshot.hasError) {
              logger.log(
                'Error in _buildRecommendedSongsSection',
                snapshot.error,
                snapshot.stackTrace,
              );
              return _buildErrorWidget(context);
            }

            if (!snapshot.hasData) {
              return const SizedBox.shrink();
            }

            final data = snapshot.data as List<dynamic>;
            if (data.isEmpty) return const SizedBox.shrink();

            return _buildRecommendedForYouSection(context, data);
          },
        );
      },
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.recommendedForYou,
          actionButton: IconButton(
            onPressed: () async {
              await Future.microtask(
                () => setActivePlaylist({
                  'title': context.l10n!.recommendedForYou,
                  'list': data,
                }),
              );
            },
            icon: Icon(
              FluentIcons.play_circle_24_filled,
              color: Theme.of(context).colorScheme.primary,
              size: 30,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: data.length,
          padding: commonListViewBottmomPadding,
          itemBuilder: (context, index) {
            final borderRadius = getItemBorderRadius(index, data.length);
            return RepaintBoundary(
              key: ValueKey('song_${data[index]['ytid']}'),
              child: SongBar(data[index], true, borderRadius: borderRadius),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAlbumsSection(double playlistHeight) {
    return FutureBuilder<List<dynamic>>(
      future: getAlbumsFromDatabase(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final albums = snapshot.data ?? [];
        final itemsNumber = albums.length.clamp(0, recommendedCubesNumber);
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        return Column(
          children: [
            SectionHeader(title: context.l10n!.albums),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child: isLargeScreen
                  ? _buildHorizontalList(
                      albums,
                      itemsNumber,
                      playlistHeight,
                    )
                  : _buildCarouselView(
                      albums,
                      itemsNumber,
                      playlistHeight,
                    ),
            ),
          ],
        );
      },
    );
  }
}
