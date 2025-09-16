import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/screens/mobile_ui/now_playing_artwork.dart';
import 'package:j3tunes/screens/mobile_ui/now_playing_controls.dart';
import 'package:j3tunes/screens/mobile_ui/bottom_actions_row.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class DesktopLayout extends StatelessWidget {
  const DesktopLayout({
    super.key,
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.youtubeController,
    required this.youtubePlayer,
    required this.isVideoMode,
    required this.onArtworkTapped,
  });

  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final YoutubePlayerController? youtubeController;
  final YoutubePlayer? youtubePlayer;
  final bool isVideoMode;
  final VoidCallback onArtworkTapped;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              const SizedBox(height: 5),
              NowPlayingArtwork(
                size: size,
                metadata: metadata,
                youtubeController: youtubeController,
                youtubePlayer: youtubePlayer,
                isDesktop: true,
                onArtworkTapped: onArtworkTapped,
              ),
              const SizedBox(height: 5),
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
              BottomActionsRow(
                context: context,
                audioId: metadata.extras?['ytid'],
                metadata: metadata,
                iconSize: adjustedMiniIconSize,
                isLargeScreen: true, // This hides the queue button on desktop
                onQueueButtonPressed:
                    () {}, // Not needed as queue button is hidden
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}