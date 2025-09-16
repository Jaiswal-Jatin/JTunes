import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/mobile_ui/now_playing_page.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/widgets/spinner.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';


class NowPlayingArtwork extends StatefulWidget {
  const NowPlayingArtwork({
    super.key,
    required this.size,
    required this.metadata,
    required this.youtubeController,
    required this.youtubePlayer,
    this.isDesktop = false,
    this.onArtworkTapped,
  });

  final Size size;
  final MediaItem metadata;
  final YoutubePlayerController? youtubeController;
  final YoutubePlayer? youtubePlayer;
  final bool isDesktop;
  final VoidCallback? onArtworkTapped;

  @override
  State<NowPlayingArtwork> createState() => _NowPlayingArtworkState();
}

class _NowPlayingArtworkState extends State<NowPlayingArtwork> {
  // Helper function to get the best quality image URL
  String? _getBestImageUrl(MediaItem mediaItem) {
    // Priority: highResImage > artUri > lowResImage
    final ytid = mediaItem.extras?['ytid']?.toString();
    final highResImage = mediaItem.extras?['highResImage']?.toString();
    final artUri = mediaItem.artUri?.toString();
    final lowResImage = mediaItem.extras?['lowResImage']?.toString();
    
    if (highResImage != null && highResImage.isNotEmpty && highResImage != 'null' && highResImage.startsWith('http')) {
      return highResImage;
    }
    if (artUri != null && artUri.isNotEmpty && artUri != 'null' && artUri.startsWith('http')) {
      return artUri;
    }
    if (lowResImage != null && lowResImage.isNotEmpty && lowResImage != 'null' && lowResImage.startsWith('http')) {
      return lowResImage;
    }

    // If all else fails, construct a reliable URL from the video ID
    if (ytid != null && ytid.isNotEmpty) {
      return 'https://i.ytimg.com/vi/$ytid/hqdefault.jpg';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    const _padding = 50;
    const _radius = 20.0;

    const lyricsTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );

    return ValueListenableBuilder<CardDisplayMode>(
      valueListenable: cardModeNotifier,
      builder: (context, mode, _) {
        final screenWidth = widget.size.width;
        final screenHeight = widget.size.height;
        final isLandscape = screenWidth > screenHeight;

        double artworkWidth;
        double artworkHeight;

        if (mode == CardDisplayMode.video) {
          // Video mode: 16:9 aspect ratio for both mobile and desktop
          artworkWidth = screenWidth * 0.9;
          artworkHeight = artworkWidth * 9 / 16;
        } else {
          // Default square size for artwork/lyrics or mobile video
          final imageSize = isLandscape
              ? screenHeight * 0.40
              : (screenWidth + screenHeight) / 3.35 - _padding;
          artworkWidth = imageSize;
          artworkHeight = imageSize;
        }

        return Stack(
          alignment: Alignment.center,
          children: [
            // Overlay behind the artwork for separation from blurred background
            Container(
              width: artworkWidth + 32,
              height: artworkHeight + 32,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(_radius + 16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                border: Border.all(
                  color: Colors.white.withOpacity(0.18),
                  width: 2.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  // On both desktop and mobile, tap toggles video mode if available.
                  if (widget.youtubeController != null) {
                    widget.onArtworkTapped?.call();
                  }
                },
                onHorizontalDragEnd: (details) {
                  if (details.primaryVelocity == null) return;
                  // Swipe left for next
                  if (details.primaryVelocity! < -200) {
                    audioHandler.skipToNext();
                  }
                  // Swipe right for previous
                  else if (details.primaryVelocity! > 200) {
                    audioHandler.skipToPrevious();
                  }
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(_radius),
                  child: SizedBox(
                    width: artworkWidth,
                    height: artworkHeight,
                    child: _buildCardContent(artworkWidth, artworkHeight,
                        _radius, lyricsTextStyle, mode),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCardContent(double imageWidth, double imageHeight, double radius,
      TextStyle lyricsTextStyle, CardDisplayMode mode) {
    switch (mode) {
      case CardDisplayMode.artwork:
        // Always use the highest quality image available
        final imageUrl = _getBestImageUrl(widget.metadata);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Transform.scale(
            scale: 1.4, // Crop/zoom all now playing images everywhere
            child: imageUrl != null && imageUrl.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: imageUrl,
                    width: imageWidth,
                    height: imageHeight,
                    fit: BoxFit.cover,
                    memCacheWidth: (imageWidth * 6).toInt(),
                    memCacheHeight: (imageHeight * 6).toInt(),
                    filterQuality: FilterQuality.high,
                    placeholder: (context, url) => Center(
                      child: SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Image.asset(
                      'assets/images/JTunes.png',
                      fit: BoxFit.cover,
                      width: imageWidth,
                      height: imageHeight,
                    ),
                  )
                : Image.asset(
                    'assets/images/JTunes.png',
                    fit: BoxFit.cover,
                    width: imageWidth,
                    height: imageHeight,
                  ),
          ),
        );

      case CardDisplayMode.lyrics:
        return Container(
          width: imageWidth,
          height: imageHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8),
                Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: FutureBuilder<String?>(
              future:
                  getSongLyrics(widget.metadata.artist, widget.metadata.title),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Spinner());
                } else if (snapshot.hasError || snapshot.data == null) {
                  return Center(
                    child: Text(
                      context.l10n!.lyricsNotAvailable,
                      style: lyricsTextStyle,
                      textAlign: TextAlign.center,
                    ),
                  );
                } else {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        snapshot.data ?? context.l10n!.lyricsNotAvailable,
                        style: lyricsTextStyle,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        );

      case CardDisplayMode.video:
        return Container(
          width: imageWidth,
          height: imageHeight,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(radius),
          ),
          child: widget.youtubePlayer ??
              Container(
                color: Colors.black,
                child: const Center(
                  child: Text(
                    'Video not available',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
        );
    }
  }
}