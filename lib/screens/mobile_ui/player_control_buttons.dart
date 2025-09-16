import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/widgets/playback_icon_button.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PlayerControlButtons extends StatelessWidget {
  const PlayerControlButtons({
    super.key,
    required this.context,
    required this.metadata,
    required this.iconSize,
    required this.miniIconSize,
    this.youtubeController,
    this.isVideoMode = false,
  });

  final BuildContext context;
  final MediaItem metadata;
  final double iconSize;
  final double miniIconSize;
  final YoutubePlayerController? youtubeController;
  final bool isVideoMode;

  @override
  Widget build(BuildContext context) {
    final _primaryColor = Colors.white;
    final _secondaryColor = Colors.white.withOpacity(0.3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _buildShuffleButton(_primaryColor, _secondaryColor, miniIconSize),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    FluentIcons.previous_24_filled,
                    color: (isVideoMode
                            ? youtubeController != null
                            : audioHandler.hasPrevious)
                        ? _primaryColor
                        : _secondaryColor,
                  ),
                  iconSize: iconSize / 1.7,
                  onPressed: () {
                    print('[NowPlaying] Previous button pressed');
                    if (isVideoMode && youtubeController != null) {
                      // For video mode, skip to previous song
                      audioHandler.skipToPrevious();
                    } else {
                      audioHandler.skipToPrevious();
                    }
                  },
                  splashColor: Colors.transparent,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isVideoMode && youtubeController != null
                    ? _buildVideoPlayButton()
                    : PlaybackIconButton(
                        iconColor: Colors.black,
                        backgroundColor: Colors.white,
                        iconSize: iconSize,
                      ),
              ),
              const SizedBox(width: 10),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    FluentIcons.next_24_filled,
                    color: (isVideoMode
                            ? youtubeController != null
                            : audioHandler.hasNext)
                        ? _primaryColor
                        : _secondaryColor,
                  ),
                  iconSize: iconSize / 1.7,
                  onPressed: () {
                    print('[NowPlaying] Next button pressed');
                    if (isVideoMode && youtubeController != null) {
                      // For video mode, skip to next song
                      audioHandler.skipToNext();
                    } else {
                      audioHandler.skipToNext();
                    }
                  },
                  splashColor: Colors.transparent,
                ),
              ),
            ],
          ),
          _buildRepeatButton(_primaryColor, _secondaryColor, miniIconSize),
        ],
      ),
    );
  }

  Widget _buildVideoPlayButton() {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: youtubeController!,
      builder: (context, value, child) {
        final isPlaying = value.isPlaying;
        return IconButton(
          icon: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.black,
          ),
          iconSize: iconSize,
          onPressed: () {
            if (isPlaying) {
              youtubeController!.pause();
            } else {
              youtubeController!.play();
            }
          },
          splashColor: Colors.transparent,
        );
      },
    );
  }

  Widget _buildShuffleButton(
    Color primaryColor,
    Color secondaryColor,
    double iconSize,
  ) {
    return ValueListenableBuilder<bool>(
      valueListenable: shuffleNotifier,
      builder: (_, value, __) {
        return Container(
          decoration: BoxDecoration(
            color: value
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              value
                  ? FluentIcons.arrow_shuffle_24_filled
                  : FluentIcons.arrow_shuffle_off_24_filled,
              color: value ? primaryColor : secondaryColor,
            ),
            iconSize: iconSize,
            onPressed: () {
              audioHandler.setShuffleMode(
                value
                    ? AudioServiceShuffleMode.none
                    : AudioServiceShuffleMode.all,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildRepeatButton(
    Color primaryColor,
    Color secondaryColor,
    double iconSize,
  ) {
    return ValueListenableBuilder<AudioServiceRepeatMode>(
      valueListenable: repeatNotifier,
      builder: (_, repeatMode, __) {
        final isActive = repeatMode != AudioServiceRepeatMode.none;
        return Container(
          decoration: BoxDecoration(
            color: isActive
                ? Colors.white.withOpacity(0.2)
                : Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              repeatMode == AudioServiceRepeatMode.all
                  ? FluentIcons.arrow_repeat_all_24_filled
                  : repeatMode == AudioServiceRepeatMode.one
                      ? FluentIcons.arrow_repeat_1_24_filled
                      : FluentIcons.arrow_repeat_all_off_24_filled,
              color: isActive ? primaryColor : secondaryColor,
            ),
            iconSize: iconSize,
            onPressed: () {
              final newRepeatMode = repeatMode == AudioServiceRepeatMode.none
                  ? (activePlaylist['list'].isEmpty
                      ? AudioServiceRepeatMode.one
                      : AudioServiceRepeatMode.all)
                  : repeatMode == AudioServiceRepeatMode.all
                      ? AudioServiceRepeatMode.one
                      : AudioServiceRepeatMode.none;

              repeatNotifier.value = newRepeatMode;
              audioHandler.setRepeatMode(newRepeatMode);
            },
          ),
        );
      },
    );
  }
}