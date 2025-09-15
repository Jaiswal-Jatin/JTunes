// ignore_for_file: directives_ordering, deprecated_member_use, use_decorated_box, prefer_const_declarations, unused_element

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

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/now_playing_page.dart';
import 'package:j3tunes/widgets/marque.dart';
import 'package:j3tunes/widgets/playback_icon_button.dart';
import 'package:j3tunes/widgets/song_artwork.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:j3tunes/models/position_data.dart';

// Global cache for mini player colors
final Map<String, Color> _miniPlayerColorCache = {};

/// Call this function instead of Navigator.push to open NowPlayingPage with a smooth slide-up animation.
void showNowPlayingPage(BuildContext context) {
  Navigator.of(context).push(
    PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 250), // Even faster
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const NowPlayingPage(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final slideAnimation = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: Curves.fastOutSlowIn,
        ));

        final fadeAnimation = Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(CurvedAnimation(
          parent: animation,
          curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
        ));

        return SlideTransition(
          position: slideAnimation,
          child: FadeTransition(
            opacity: fadeAnimation,
            child: child,
          ),
        );
      },
      opaque: false,
      barrierColor: Colors.black.withOpacity(0.2),
    ),
  );
}

class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  final ValueNotifier<Color?> _dominantColorNotifier =
      ValueNotifier<Color?>(null);
  String? _dominantColorImageUrl;

  @override
  void initState() {
    super.initState();
    // Listen to mediaItem changes for color updates
    audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        final imageUrl = mediaItem.artUri?.toString();
        if (imageUrl != null && imageUrl != _dominantColorImageUrl) {
          _updateDominantColor(imageUrl);
        }
      }
    });

    // Get current song immediately for instant color update
    final currentMediaItem = audioHandler.mediaItem.valueOrNull;
    if (currentMediaItem != null) {
      final imageUrl = currentMediaItem.artUri?.toString();
      if (imageUrl != null) {
        _updateDominantColor(imageUrl);
      }
    }
  }

  Future<void> _updateDominantColor(String imageUrl) async {
    if (imageUrl == _dominantColorImageUrl) return;

    // Check cache first
    if (_miniPlayerColorCache.containsKey(imageUrl)) {
      _dominantColorNotifier.value = _miniPlayerColorCache[imageUrl];
      _dominantColorImageUrl = imageUrl;
      return;
    }

    // Set a default color immediately for instant feedback
    _dominantColorNotifier.value = Theme.of(context).colorScheme.surface;
    _dominantColorImageUrl = imageUrl;

    try {
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(80, 80), // Small size for faster processing
        maximumColorCount: 8, // Reduced colors for faster processing
      );

      Color? color = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.darkVibrantColor?.color ??
          Theme.of(context).colorScheme.surface;

      // Cache the color
      _miniPlayerColorCache[imageUrl] = color;
      _dominantColorNotifier.value = color;
    } catch (e) {
      // Keep the default color if extraction fails
      final defaultColor = Theme.of(context).colorScheme.surface;
      _miniPlayerColorCache[imageUrl] = defaultColor;
      _dominantColorNotifier.value = defaultColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    const _height = 60.0;
    const _imageSize = 50.0;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, snapshot) {
        final metadata = snapshot.data;
        if (metadata == null) {
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<Color?>(
          valueListenable: _dominantColorNotifier,
          builder: (context, dominantColor, _) {
            return GestureDetector(
              onTap: () => showNowPlayingPage(context),
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity! < -300) { // Swipe up
                  showNowPlayingPage(context);
                } else if (details.primaryVelocity! > 300) { // Swipe down
                  audioHandler.stop();
                  audioHandler.updateQueue([]);
                }
              },
              child: Container(
                height: _height,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                width: double.infinity,
                decoration: BoxDecoration(
                gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  dominantColor?.withOpacity(0.9) ??
                    Theme.of(context).colorScheme.surface,
                  dominantColor?.withOpacity(0.7) ??
                    Theme.of(context)
                      .colorScheme
                      .surface
                      .withOpacity(0.8),
                ],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                BoxShadow(
                  color: (dominantColor ?? Colors.black).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                ],
              ), // decoration
              clipBehavior: Clip.antiAlias,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  Row(
                    children: [
                    // Song Artwork
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SongArtworkWidget(
                        metadata: metadata,
                        size: _imageSize,
                        errorWidgetIconSize: 25,
                      ),
                      ),
                    ),

                    // Song Info
                    Expanded(
                      child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        MarqueeWidget(
                          child: Text(
                          metadata.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                            ),
                            ],
                          ),
                          overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (metadata.artist != null) ...[
                          const SizedBox(height: 2),
                          MarqueeWidget(
                          child: Text(
                            metadata.artist!,
                            style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withOpacity(0.9),
                            shadows: [
                              Shadow(
                              color: Colors.black.withOpacity(0.7),
                              offset: const Offset(0, 1),
                              blurRadius: 2,
                              ),
                            ],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          ),
                        ],
                        ],
                      ),
                      ),
                    ),

                    // Control Buttons
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      // Previous Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        ),
                        child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(FluentIcons.previous_24_filled),
                        color: Colors.white,
                        iconSize: 20,
                        onPressed: audioHandler.hasPrevious
                          ? audioHandler.skipToPrevious
                          : null,
                        splashColor: Colors.transparent,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Play/Pause Button
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                          ),
                        ],
                        ),
                        child: PlaybackIconButton(
                        padding: EdgeInsets.zero,
                        iconColor: Colors.black,
                        backgroundColor: Colors.white,
                        iconSize: 30,
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Next Button
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        ),
                        child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(FluentIcons.next_24_filled),
                        color: Colors.white,
                        iconSize: 20,
                        onPressed: audioHandler.hasNext
                          ? audioHandler.skipToNext
                          : null,
                        splashColor: Colors.transparent,
                        ),
                      ),

                      const SizedBox(width: 10),
                      ],
                    ),
                    ],
                  ),
                  StreamBuilder<PositionData>(
                    stream: audioHandler.positionDataStream,
                    builder: (context, snapshot) {
                      final positionData = snapshot.data;
                      final position = positionData?.position ?? Duration.zero;
                      final duration = positionData?.duration ?? Duration.zero;

                      double progress = 0.0;
                      if (duration.inMilliseconds > 0) {
                        progress = (position.inMilliseconds / duration.inMilliseconds)
                            .clamp(0.0, 1.0);
                      }

                      return LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                      );
                    },
                  ),
                ],
              ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _dominantColorNotifier.dispose();
    super.dispose();
  }
}
