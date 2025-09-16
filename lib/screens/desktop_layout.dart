import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'now_playing_artwork.dart';
import 'now_playing_controls.dart';
import 'queue_list_view.dart';

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
  });

  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final YoutubePlayerController? youtubeController;
  final YoutubePlayer? youtubePlayer;
  final bool isVideoMode;

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
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        const Expanded(child: QueueListView()),
      ],
    );
  }
}