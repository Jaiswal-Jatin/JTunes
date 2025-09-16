import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/screens/artist_page.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'marquee_text_widget.dart';
import 'player_control_buttons.dart';
import 'position_slider.dart';

class NowPlayingControls extends StatelessWidget {
  const NowPlayingControls({
    super.key,
    required this.context,
    required this.size,
    required this.audioId,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.metadata,
    required this.youtubeController,
    required this.isVideoMode,
  });

  final BuildContext context;
  final Size size;
  final dynamic audioId;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final MediaItem metadata;
  final YoutubePlayerController? youtubeController;
  final bool isVideoMode;

  @override
  Widget build(BuildContext context) {
    final screenWidth = size.width;
    final screenHeight = size.height;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          SizedBox(
            width: screenWidth * 0.85,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MarqueeTextWidget(
                  text: metadata.title,
                  fontColor: Colors.white,
                  fontSize: screenHeight * 0.028,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 10),
                if (metadata.artist != null)
                  GestureDetector(
                    onTap: () {
                      if (metadata.artist != null && metadata.artist!.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ArtistPage(
                              artistName: metadata.artist!,
                            ),
                          ),
                        );
                      }
                    },
                    child: MarqueeTextWidget(
                      text: metadata.artist!,
                      fontColor: Colors.white.withOpacity(0.8),
                      fontSize: screenHeight * 0.017,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          PositionSlider(
            youtubeController: youtubeController,
            isVideoMode: isVideoMode,
          ),
          const Spacer(),
          PlayerControlButtons(
            context: context,
            metadata: metadata,
            iconSize: adjustedIconSize,
            miniIconSize: adjustedMiniIconSize,
            youtubeController: youtubeController,
            isVideoMode: isVideoMode,
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }
}