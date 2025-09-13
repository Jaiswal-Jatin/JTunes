import 'dart:io';

import 'package:j3tunes/API/musify.dart';
import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/models/position_data.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/formatter.dart';
import 'package:j3tunes/widgets/no_artwork_cube.dart';
import 'package:j3tunes/widgets/spinner.dart';

class SongBar extends StatefulWidget {
  const SongBar(
    this.song,
    this.clearPlaylist, {
    this.backgroundColor,
    this.showMusicDuration = false,
    this.onPlay,
    this.isSongOffline,
    this.isRecentSong,
    this.onRemove,
    this.borderRadius = BorderRadius.zero,
    super.key,
  });

  final dynamic song;
  final bool clearPlaylist;
  final Color? backgroundColor;
  final VoidCallback? onRemove;
  final VoidCallback? onPlay;
  final bool? isSongOffline;
  final bool? isRecentSong;
  final bool showMusicDuration;
  final BorderRadius borderRadius;

  @override
  State<SongBar> createState() => _SongBarState();
}

class _SongBarState extends State<SongBar> {
  static const likeStatusToIconMapper = {
    true: FluentIcons.heart_24_filled,
    false: FluentIcons.heart_24_regular,
  };

  ValueNotifier<bool>? _songLikeStatus;
  ValueNotifier<bool>? _songOfflineStatus;
  String? _songTitle;
  String? _songArtist;
  String? _artworkPath;
  String? _lowResImageUrl;
  String? _ytid;

  @override
  void initState() {
    super.initState();
    _initSongFields(widget.song);
    _songLikeStatus = ValueNotifier(isSongAlreadyLiked(_ytid ?? ''));
    _songOfflineStatus = ValueNotifier(
      widget.isSongOffline ?? isSongAlreadyOffline(_ytid ?? ''),
    );
  }

  @override
  void didUpdateWidget(covariant SongBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.song != oldWidget.song) {
      _initSongFields(widget.song);
      _songLikeStatus?.value = isSongAlreadyLiked(_ytid ?? '');
      _songOfflineStatus?.value =
          widget.isSongOffline ?? isSongAlreadyOffline(_ytid ?? '');
      setState(() {});
    }
  }

  void _initSongFields(dynamic song) {
    final songData = song is Map ? song : <String, dynamic>{};
    _songTitle = songData['title'] ?? '';
    _songArtist = songData['artist']?.toString() ?? '';
    _artworkPath = songData['artworkPath'];
    _lowResImageUrl = songData['lowResImage']?.toString() ?? '';
    _ytid = songData['ytid'] ?? songData['id'] ?? '';
  }

  @override
  void dispose() {
    _songLikeStatus?.dispose();
    _songOfflineStatus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // JioSaavn data is always Map
    final safeSong = widget.song is Map ? widget.song : <String, dynamic>{};

    // Show loading spinner if song details are not ready
    if ((_songTitle?.isEmpty ?? true) || (_lowResImageUrl?.isEmpty ?? true)) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Spinner()),
      );
    }

    return Padding(
      padding: commonBarPadding,
      child: GestureDetector(
        onTap: _handleSongTap,
        child: Card(
          clipBehavior: Clip.hardEdge,
          color: widget.backgroundColor,
          shape: RoundedRectangleBorder(borderRadius: widget.borderRadius),
          margin: const EdgeInsets.only(bottom: 3),
          child: Stack(
            children: [
              Padding(
                padding: commonBarContentPadding,
                child: Row(
                  children: [
                    _buildAlbumArtWithSafeSong(primaryColor, safeSong),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SongInfo(
                        title: _songTitle ?? '',
                        artist: _songArtist ?? '',
                        primaryColor: primaryColor,
                        secondaryColor: theme.colorScheme.secondary,
                      ),
                    ),
                    _buildActionButtons(context, primaryColor),
                  ]
                ),
              ),
              _buildProgressIndicator(context),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSongTap() async {
    try {
      if (widget.onPlay != null) {
        widget.onPlay!();
        return;
      }

      // Play song immediately
      final success = await audioHandler.playSong(widget.song);

      if (!success) {
        // Show error toast if song failed to play
        if (mounted) {
          showToast(context, 'Failed to play song');
        }
      }

      // Clear active playlist if needed
      if (activePlaylist.isNotEmpty && widget.clearPlaylist) {
        activePlaylist = {
          'ytid': '',
          'title': 'No Playlist',
          'image': '',
          'source': 'user-created',
          'list': [],
        };
        activeSongId = 0;
      }
    } catch (e, stackTrace) {
      logger.log('Error in song tap', e, stackTrace);
      if (mounted) {
        showToast(context, 'Error playing song');
      }
    }
  }

  Widget _buildProgressIndicator(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        if (snapshot.data?.extras?['ytid'] != _ytid) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<PositionData>(
          stream: audioHandler.positionDataStream,
          builder: (context, snapshot) {
            final positionData = snapshot.data;
            final duration = positionData?.duration ?? Duration.zero;
            final position = positionData?.position ?? Duration.zero;

            if (duration.inSeconds <= 0) {
              return const SizedBox.shrink();
            }

            final progress =
                (position.inSeconds / duration.inSeconds).clamp(0.0, 1.0);

            return Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary.withOpacity(0.6),
                ),
                minHeight: 3.0,
              ),
            );
          },
        );
      },
    );
  }

  // New: album art builder that uses safeSong for duration
  Widget _buildAlbumArtWithSafeSong(Color primaryColor, dynamic safeSong) {
    // Use the same size and border radius everywhere (like recently played)
    const size = 55.0;
    final isDurationAvailable = widget.showMusicDuration &&
        safeSong is Map &&
        safeSong['duration'] != null;

    // Prefer highResImage or artUri if available, fallback to lowResImage
    final hiRes = (safeSong['highResImage'] as String?)?.trim();
    final artUri = (safeSong['artUri'] as String?)?.trim();
    final imageUrl = (hiRes != null && hiRes.isNotEmpty)
        ? hiRes
        : (artUri != null && artUri.isNotEmpty)
            ? artUri
            : (_lowResImageUrl != null && _lowResImageUrl!.isNotEmpty)
                ? _lowResImageUrl
                : null;

    Widget imageWidget;
    if (_artworkPath != null && _artworkPath!.isNotEmpty) {
      imageWidget = Image.file(
        File(_artworkPath!),
        fit: BoxFit.cover,
      );
    } else if (imageUrl != null && imageUrl.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        key: ValueKey(imageUrl),
        width: size,
        height: size,
        imageUrl: imageUrl,
        memCacheWidth: (size * 3).toInt(),
        memCacheHeight: (size * 3).toInt(),
        filterQuality: FilterQuality.high,
        imageBuilder: (context, imageProvider) => Image(
          image: imageProvider,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
        ),
        errorWidget: (context, url, error) =>
            const NullArtworkWidget(iconSize: 30),
      );
    } else {
      imageWidget = const NullArtworkWidget(iconSize: 30);
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: commonBarRadius,
        child: Transform.scale(
          scale: 1.4, // Crop/zoom all song bar images everywhere
          child: Stack(
            alignment: Alignment.center,
          children: <Widget>[
            Transform.scale(
              scale: 1.4, // Crop/zoom all song images everywhere
              child: imageWidget,
            ),
            if (isDurationAvailable)
              SizedBox(
                width: size - 10,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '(${formatDuration(safeSong['duration'])})',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),)
    );
  }

  Widget _buildActionButtons(BuildContext context, Color primaryColor) {
    return PopupMenuButton<String>(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Theme.of(context).colorScheme.surface,
      icon: Icon(FluentIcons.more_horizontal_24_filled, color: primaryColor),
      onSelected: (value) => _handleMenuAction(context, value),
      itemBuilder: (context) => _buildMenuItems(context, primaryColor),
    );
  }

  void _handleMenuAction(BuildContext context, String value) {
    switch (value) {
      case 'play_next':
        audioHandler.playNext(widget.song);
        showToast(
          context,
          context.l10n!.songAdded,
          duration: const Duration(seconds: 1),
        );
        break;
      case 'start_radio':
        audioHandler.customAction('startRadio', {'song': widget.song});
        // Optionally navigate to now playing screen
        // showNowPlayingPage(context);
        break;
      case 'like':
        if (_songLikeStatus != null) {
          _songLikeStatus!.value = !_songLikeStatus!.value;
          updateSongLikeStatus(_ytid ?? '', _songLikeStatus!.value);
          final likedSongsLength = currentLikedSongsLength.value;
          currentLikedSongsLength.value = _songLikeStatus!.value
              ? likedSongsLength + 1
              : likedSongsLength - 1;
        }
        break;
      case 'remove':
        widget.onRemove?.call();
        break;
      case 'add_to_playlist':
        showAddToPlaylistDialog(context, widget.song);
        break;
      case 'remove_from_recents':
        removeFromRecentlyPlayed(_ytid);
        break;
      case 'offline':
        _handleOfflineToggle(context);
        break;
    }
  }

  void _handleOfflineToggle(BuildContext context) {
    if (_songOfflineStatus == null) return;
    if (_songOfflineStatus!.value) {
      removeSongFromOffline(_ytid ?? '').then((success) {
        if (success) {
          showToast(context, context.l10n!.songRemovedFromOffline);
        }
      });
    } else {
      makeSongOffline(widget.song).then((success) {
        if (success) {
          showToast(context, context.l10n!.songAddedToOffline);
        }
      });
    }
    _songOfflineStatus!.value = !_songOfflineStatus!.value;
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    BuildContext context,
    Color primaryColor,
  ) {
    return [
      PopupMenuItem<String>(
        value: 'play_next',
        child: Row(
          children: [
            Icon(FluentIcons.receipt_play_24_regular, color: primaryColor),
            const SizedBox(width: 8),
            Text(context.l10n!.playNext),
          ],
        ),
      ),
      PopupMenuItem<String>(
        value: 'start_radio',
        child: Row(
          children: [
            Icon(FluentIcons.radio_button_24_regular, color: primaryColor),
            const SizedBox(width: 8),
            const Text('Start Radio'),
          ],
        ),
      ),
      if (_songLikeStatus != null)
        PopupMenuItem<String>(
          value: 'like',
          child: ValueListenableBuilder<bool>(
            valueListenable: _songLikeStatus!,
            builder: (_, value, __) {
              return Row(
                children: [
                  Icon(likeStatusToIconMapper[value], color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    value
                        ? context.l10n!.removeFromLikedSongs
                        : context.l10n!.addToLikedSongs,
                  ),
                ],
              );
            },
          ),
        ),
      if (widget.onRemove != null)
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_filled, color: primaryColor),
              const SizedBox(width: 8),
              Text(context.l10n!.removeFromPlaylist),
            ],
          ),
        ),
      PopupMenuItem<String>(
        value: 'add_to_playlist',
        child: Row(
          children: [
            Icon(FluentIcons.add_24_regular, color: primaryColor),
            const SizedBox(width: 8),
            Text(context.l10n!.addToPlaylist),
          ],
        ),
      ),
      if (widget.isRecentSong == true)
        PopupMenuItem<String>(
          value: 'remove_from_recents',
          child: Row(
            children: [
              Icon(FluentIcons.delete_24_filled, color: primaryColor),
              const SizedBox(width: 8),
              Text(context.l10n!.removeFromRecentlyPlayed),
            ],
          ),
        ),
      if (_songOfflineStatus != null)
        PopupMenuItem<String>(
          value: 'offline',
          child: ValueListenableBuilder<bool>(
            valueListenable: _songOfflineStatus!,
            builder: (_, value, __) {
              return Row(
                children: [
                  Icon(
                    value
                        ? FluentIcons.cellular_off_24_regular
                        : FluentIcons.cellular_data_1_24_regular,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    value
                        ? context.l10n!.removeOffline
                        : context.l10n!.makeOffline,
                  ),
                ],
              );
            },
          ),
        ),
    ];
  }
}

class _SongInfo extends StatelessWidget {
  const _SongInfo({
    required this.title,
    required this.artist,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String title;
  final String artist;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          overflow: TextOverflow.ellipsis,
          style: commonBarTitleStyle.copyWith(color: primaryColor),
        ),
        const SizedBox(height: 3),
        Text(
          artist,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
            color: secondaryColor,
          ),
        ),
      ],
    );
  }
}

void showAddToPlaylistDialog(BuildContext context, dynamic song) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        icon: const Icon(FluentIcons.text_bullet_list_add_24_filled),
        title: Text(context.l10n!.addToPlaylist),
        content: Container(
          width: double.maxFinite,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.6,
          ),
          child: userCustomPlaylists.value.isNotEmpty
              ? ListView.builder(
                  shrinkWrap: true,
                  itemCount: userCustomPlaylists.value.length,
                  itemBuilder: (context, index) {
                    final playlist = userCustomPlaylists.value[index];
                    return Card(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      elevation: 0,
                      child: ListTile(
                        title: Text(playlist['title']),
                        onTap: () {
                          showToast(
                            context,
                            addSongInCustomPlaylist(
                              context,
                              playlist['title'],
                              song,
                            ),
                          );
                          Navigator.pop(context);
                        },
                      ),
                    );
                  },
                )
              : Text(
                  context.l10n!.noCustomPlaylists,
                  textAlign: TextAlign.center,
                ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text(context.l10n!.cancel),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
