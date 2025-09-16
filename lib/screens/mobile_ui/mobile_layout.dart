import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'bottom_actions_row.dart';
import 'now_playing_artwork.dart';
import 'now_playing_controls.dart';

class MobileLayout extends StatelessWidget {
  const MobileLayout({
    super.key,
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.isLargeScreen,
    required this.youtubeController,
    required this.youtubePlayer,
    required this.isVideoMode,
    required this.onQueueButtonPressed,
    required this.onArtworkTapped,
  });

  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final bool isLargeScreen;
  final YoutubePlayerController? youtubeController;
  final YoutubePlayer? youtubePlayer;
  final bool isVideoMode;
  final VoidCallback onQueueButtonPressed;
  final VoidCallback onArtworkTapped;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 10,
      children: [
        NowPlayingArtwork(
          size: size,
          metadata: metadata,
          youtubeController: youtubeController,
          youtubePlayer: youtubePlayer,
          isDesktop: false,
          onArtworkTapped: onArtworkTapped,
        ),
        if (!(metadata.extras?['isLive'] ?? false))
          NowPlayingControls(
            context: context,
            size: size,
            audioId: metadata.extras?['ytid'],
            adjustedIconSize: adjustedIconSize,
            adjustedMiniIconSize: adjustedMiniIconSize,
            metadata: metadata,
            youtubeController: youtubeController,
            isVideoMode: isVideoMode,
          ),
        if (!isLargeScreen) ...[
          BottomActionsRow(
            context: context,
            audioId: metadata.extras?['ytid'],
            metadata: metadata,
            iconSize: adjustedMiniIconSize,
            isLargeScreen: isLargeScreen,
            onQueueButtonPressed: onQueueButtonPressed,
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }
}