import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/now_playing_page.dart';
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
  });

  final Size size;
  final MediaItem metadata;
  final YoutubePlayerController? youtubeController;
  final YoutubePlayer? youtubePlayer;

  @override
  State<NowPlayingArtwork> createState() => _NowPlayingArtworkState();
}

class _NowPlayingArtworkState extends State<NowPlayingArtwork> {
  // Helper function to get the best quality image URL
  String? _getBestImageUrl(MediaItem mediaItem) {
    // Priority: highResImage > artUri > lowResImage
    final highResImage = mediaItem.extras?['highResImage']?.toString();
    final artUri = mediaItem.artUri?.toString();
    final lowResImage = mediaItem.extras?['lowResImage']?.toString();
    
    if (highResImage != null && highResImage.isNotEmpty && highResImage != 'null') {
      return highResImage;
    }
    if (artUri != null && artUri.isNotEmpty && artUri != 'null') {
      return artUri;
    }
    if (lowResImage != null && lowResImage.isNotEmpty && lowResImage != 'null') {
      return lowResImage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    const _padding = 50;
    const _radius = 20.0;
    final screenWidth = widget.size.width;
    final screenHeight = widget.size.height;
    final isLandscape = screenWidth > screenHeight;
    final imageSize = isLandscape
        ? screenHeight * 0.40
        : (screenWidth + screenHeight) / 3.35 - _padding;

    const lyricsTextStyle = TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: Colors.white,
    );

    return Stack(
      alignment: Alignment.center,
      children: [
        // Overlay behind the artwork for separation from blurred background
        Container(
          width: imageSize + 32,
          height: imageSize + 32,
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
              if (!offlineMode.value) {
                setState(() {
                  cardModeNotifier.value =
                      cardModeNotifier.value == CardDisplayMode.artwork
                          ? CardDisplayMode.lyrics
                          : CardDisplayMode.artwork;
                });
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
                width: imageSize,
                height: imageSize,
                child: ValueListenableBuilder<CardDisplayMode>(
                  valueListenable: cardModeNotifier,
                  builder: (context, mode, child) {
                    return _buildCardContent(
                        imageSize, _radius, lyricsTextStyle, mode);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(double imageSize, double radius,
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
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.cover,
                    memCacheWidth: (imageSize * 6).toInt(),
                    memCacheHeight: (imageSize * 6).toInt(),
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
                      width: imageSize,
                      height: imageSize,
                    ),
                  )
                : Image.asset(
                    'assets/images/JTunes.png',
                    fit: BoxFit.cover,
                    width: imageSize,
                    height: imageSize,
                  ),
          ),
        );

      case CardDisplayMode.lyrics:
        return Container(
          width: imageSize,
          height: imageSize,
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
          width: imageSize,
          height: imageSize,
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