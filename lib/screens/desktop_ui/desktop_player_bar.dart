import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/widgets/mini_player.dart';

/// A compact player bar for desktop and tablet layouts.
/// It displays the current track and basic controls.
class DesktopPlayerBar extends StatelessWidget {
  const DesktopPlayerBar({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem.distinct((prev, curr) {
        if (prev == null || curr == null) return false;
        return prev.id == curr.id &&
            prev.title == curr.title &&
            prev.artist == curr.artist &&
            prev.artUri == curr.artUri;
      }),
      builder: (context, snapshot) {
        if (snapshot.data == null) {
          return const SizedBox.shrink();
        }
        return const MiniPlayer(isDesktop: true);
      },
    );
  }
}
