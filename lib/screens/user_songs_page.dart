// ignore_for_file: directives_ordering



import 'package:j3tunes/API/musify.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/widgets/banner_ad_widget.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/playlist_cube.dart';
import 'package:j3tunes/widgets/playlist_header.dart';
import 'package:j3tunes/widgets/song_bar.dart';

class UserSongsPage extends StatefulWidget {
  const UserSongsPage({super.key, required this.page});

  final String page;

  @override
  State<UserSongsPage> createState() => _UserSongsPageState();
}

class _UserSongsPageState extends State<UserSongsPage> {
  bool _isEditEnabled = false;

  @override
  Widget build(BuildContext context) {
    final title = getTitle(widget.page, context);
    final icon = getIcon(widget.page);
    final songsList = getSongsList(widget.page);
    final length = getLength(widget.page);
    final isLikedSongs = title == context.l10n!.likedSongs;

    return Scaffold(
      appBar: AppBar(
        title: offlineMode.value ? Text(title) : null,
        actions: [
          if (isLikedSongs)
            IconButton(
              onPressed: _toggleEditMode,
              icon: Icon(
                FluentIcons.re_order_24_filled,
                color: _isEditEnabled
                    ? Theme.of(context).colorScheme.inversePrimary
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        return _buildCustomScrollView(
            title, icon, songsList, length, constraints.maxWidth);
      }),
    );
  }

  void _toggleEditMode() {
    setState(() => _isEditEnabled = !_isEditEnabled);
  }

  Widget _buildCustomScrollView(String title, IconData icon, List songsList,
      ValueNotifier<int> length, double maxWidth) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: buildPlaylistHeader(title, icon, songsList.length, maxWidth),
          ),
        ),
        buildSongList(title, songsList, length),
        // Padding for mini player
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  String getTitle(String page, BuildContext context) {
    return switch (page) {
      'liked' => context.l10n!.likedSongs,
      'offline' => context.l10n!.offlineSongs,
      'recents' => context.l10n!.recentlyPlayed,
      _ => context.l10n!.playlist,
    };
  }

  IconData getIcon(String page) {
    return switch (page) {
      'liked' => FluentIcons.heart_24_regular,
      'offline' => FluentIcons.arrow_download_24_regular,
      'recents' => FluentIcons.history_24_regular,
      _ => FluentIcons.heart_24_regular,
    };
  }

  List getSongsList(String page) {
    return switch (page) {
      'liked' => userLikedSongsList,
      'offline' => userOfflineSongs,
      'recents' => userRecentlyPlayed,
      _ => userLikedSongsList,
    };
  }

  ValueNotifier<int> getLength(String page) {
    return switch (page) {
      'liked' => currentLikedSongsLength,
      'offline' => currentOfflineSongsLength,
      'recents' => currentRecentlyPlayedLength,
      _ => currentLikedSongsLength,
    };
  }

  Widget buildPlaylistHeader(
      String title, IconData icon, int songsLength, double maxWidth) {
    return PlaylistHeader(
        _buildPlaylistImage(title, icon, maxWidth), title, songsLength);
  }

  Widget _buildPlaylistImage(String title, IconData icon, double maxWidth) {
    return PlaylistCube(
      {'title': title},
      size: maxWidth / 2.5,
      cubeIcon: icon,
    );
  }

  Widget buildSongList(
    String title,
    List songsList,
    ValueNotifier<int> currentSongsLength,
  ) {
    final playlist = {
      'ytid': '',
      'title': title,
      'source': 'user-created',
      'list': songsList,
    };
    final isLikedSongs = title == context.l10n!.likedSongs;
    final isRecentlyPlayed = title == context.l10n!.recentlyPlayed;

    return ValueListenableBuilder(
      valueListenable: currentSongsLength,
      builder: (_, value, __) {
        final adInterval = 10;
        final totalItems = value + (value ~/ adInterval);

        if (isLikedSongs) {
          return SliverReorderableList(
            itemCount: totalItems,
            itemBuilder: (context, index) {
              if (index > 0 && (index + 1) % (adInterval + 1) == 0) {
                // Use adIndex to get different ads from the cache pool
                final adIndexInList = (index ~/ (adInterval + 1));
                return RepaintBoundary(
                    key: ValueKey('ad_$index'), child: BannerAdWidget(adIndex: adIndexInList));
              }
              final songIndex = index - (index ~/ (adInterval + 1));
              final song = songsList[songIndex];
              final borderRadius = getItemBorderRadius(songIndex, songsList.length);

              return ReorderableDragStartListener(
                enabled: _isEditEnabled,
                key: Key(song['ytid'].toString()),
                index: songIndex,
                child: _buildSongBar(
                  song,
                  songIndex,
                  borderRadius,
                  playlist,
                  isRecentSong: isRecentlyPlayed,
                ),
              );
            },
            onReorder: (int oldIndexWithAds, int newIndexWithAds) {
              setState(() {
                // Convert indices to song indices
                int oldSongIndex = oldIndexWithAds - (oldIndexWithAds ~/ (adInterval + 1));
                int newSongIndex = newIndexWithAds - (newIndexWithAds ~/ (adInterval + 1));

                if (oldSongIndex < newSongIndex) {
                  // When moving down, the new index needs to be adjusted
                  // if it crosses an ad boundary differently than the old one.
                }
                moveLikedSong(oldSongIndex, newSongIndex);
              });
            },
          );
        } else {
          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index > 0 && (index + 1) % (adInterval + 1) == 0) {
                final adIndexInList = (index ~/ (adInterval + 1));
                return RepaintBoundary(child: BannerAdWidget(adIndex: adIndexInList));
              }

              final songIndex = index - (index ~/ (adInterval + 1));
              if (songIndex >= songsList.length) return null; // Avoid range error
              final songItem = songsList[songIndex];
              songItem['isOffline'] = title == context.l10n!.offlineSongs;
              final borderRadius = getItemBorderRadius(songIndex, songsList.length);

              return _buildSongBar(
                songItem,
                songIndex,
                borderRadius,
                playlist,
                isRecentSong: isRecentlyPlayed,
              );
            }, childCount: totalItems),
          );
        }
      },
    );
  }

  Widget _buildSongBar(
    Map song,
    int index,
    BorderRadius borderRadius,
    Map playlist, {
    bool isRecentSong = false,
  }) {
    return SongBar(
      song,
      true,
      onPlay: () {
        audioHandler.playPlaylistSong(
          playlist: playlist,
          songIndex: index,
        );
      },
      borderRadius: borderRadius,
      isRecentSong: isRecentSong,
    );
  }
}
