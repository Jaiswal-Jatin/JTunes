// ignore_for_file: avoid_redundant_argument_values, prefer_const_constructors

import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:j3tunes/screens/desktop_layout.dart';
import 'package:j3tunes/screens/mobile_layout.dart';
import 'package:j3tunes/screens/queue_sheet.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import 'package:j3tunes/main.dart';



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

final _lyricsController = FlipCardController();

// Global notifiers
final ValueNotifier<bool> isVideoModeNotifier = ValueNotifier<bool>(false);
final ValueNotifier<CardDisplayMode> cardModeNotifier =
    ValueNotifier<CardDisplayMode>(CardDisplayMode.artwork);

enum CardDisplayMode { artwork, lyrics, video }

// Global cache for now playing colors
final Map<String, Color> _nowPlayingColorCache = {};

class NowPlayingPage extends StatefulWidget {
  const NowPlayingPage({super.key});

  @override
  State<NowPlayingPage> createState() => _NowPlayingPageState();
}

class _NowPlayingPageState extends State<NowPlayingPage> {
  final ValueNotifier<Color?> _dominantColorNotifier =
      ValueNotifier<Color?>(null);
  String? _dominantColorImageUrl;
  YoutubePlayerController? _youtubeController;
  bool _isVideoInitialized = false;
  String? _currentVideoId;
  bool _isVideoMode = false;

  @override
  void initState() {
    super.initState();
    // No async work here, will be handled in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get current song immediately for instant color update
    final currentMediaItem = audioHandler.mediaItem.valueOrNull;
    if (currentMediaItem != null) {
      final imageUrl = _getBestImageUrl(currentMediaItem);
      if (imageUrl != null) {
        _updateDominantColor(imageUrl);
      }
      final videoId = currentMediaItem.extras?['ytid'];
      if (videoId != null) {
        _initializeVideoPlayer(videoId);
      }
    }

    // Listen to mediaItem changes for color and video init
    audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        final imageUrl = _getBestImageUrl(mediaItem);
        if (imageUrl != null && imageUrl != _dominantColorImageUrl) {
          _updateDominantColor(imageUrl);
        }
        final videoId = mediaItem.extras?['ytid'];
        if (videoId != null && videoId != _currentVideoId) {
          _initializeVideoPlayer(videoId);
        }
      }
    });
  }

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

  Future<void> _updateDominantColor(String imageUrl) async {
    if (imageUrl == _dominantColorImageUrl) return;

    // Check cache first
    if (_nowPlayingColorCache.containsKey(imageUrl)) {
      _dominantColorNotifier.value = _nowPlayingColorCache[imageUrl];
      _dominantColorImageUrl = imageUrl;
      return;
    }

    // Set a default color immediately for instant feedback
    _dominantColorNotifier.value = Colors.black.withOpacity(0.85);
    _dominantColorImageUrl = imageUrl;

    try {
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(
        NetworkImage(imageUrl),
        size: const Size(80, 80), // Even smaller for faster processing
        maximumColorCount: 6, // Reduced colors for faster processing
      );

      Color? color = palette.vibrantColor?.color ??
          palette.dominantColor?.color ??
          palette.darkVibrantColor?.color ??
          Colors.black;

      color = color.withOpacity(0.85);

      // Cache the color
      _nowPlayingColorCache[imageUrl] = color;
      _dominantColorNotifier.value = color;
    } catch (e) {
      // Keep the default color if extraction fails
      final defaultColor = Colors.black.withOpacity(0.85);
      _nowPlayingColorCache[imageUrl] = defaultColor;
      _dominantColorNotifier.value = defaultColor;
    }
  }

  void _initializeVideoPlayer(String videoId) {
    if (_currentVideoId == videoId && _youtubeController != null) {
      return;
    }

    _isVideoMode = false;
    isVideoModeNotifier.value = false;
    cardModeNotifier.value = CardDisplayMode.artwork;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_youtubeController != null) {
          _youtubeController!.dispose();
        }

        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            captionLanguage: 'en',
            showLiveFullscreenButton: true,
            hideControls: false,
            controlsVisibleAtStart: false,
            forceHD: false,
            useHybridComposition: false,
          ),
        );

        _youtubeController!.addListener(() {
          if (_youtubeController!.value.isFullScreen) {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.landscapeLeft,
              DeviceOrientation.landscapeRight,
            ]);
          } else {
            SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
            ]);
          }
        });

        setState(() {
          _isVideoInitialized = true;
          _currentVideoId = videoId;
        });
      }
    });
  }

  void _showQueueSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) { // Changed: Use public QueueSheet
            return QueueSheet(scrollController: scrollController);
          },
        );
      },
    );
  }

  void _toggleVideoMode() async {
    if (_youtubeController != null && _isVideoInitialized) {
      final videoPosition = _youtubeController!.value.position;

      setState(() {
        _isVideoMode = !_isVideoMode;
        isVideoModeNotifier.value = _isVideoMode;
        if (_isVideoMode) {
          // Switch to video mode
          cardModeNotifier.value = CardDisplayMode.video;
        } else {
          // Switch to audio mode
          cardModeNotifier.value = CardDisplayMode.artwork;
        }
      });

      if (_isVideoMode) {
        // Audio -> Video: Pause audio, get position, seek video, then play video
        await audioHandler.pause();
        final audioPosition =
            (await audioHandler.positionDataStream.first).position;
        if (audioPosition > Duration.zero) {
          _youtubeController!.seekTo(audioPosition);
        }
        _youtubeController!.play();
      } else {
        // Video -> Audio: Pause video, seek audio, then play audio
        _youtubeController!.pause();
        if (videoPosition > Duration.zero) {
          await audioHandler.seek(videoPosition);
        }
        audioHandler.play();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isLargeScreen = size.width > 800;
    const adjustedIconSize = 43.0;
    const adjustedMiniIconSize = 20.0;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem.distinct((prev, curr) {
        if (prev == null || curr == null) return false;
        return prev.id == curr.id &&
            prev.title == curr.title &&
            prev.artist == curr.artist &&
            prev.artUri == curr.artUri;
      }),
      builder: (context, snapshot) {
        if (snapshot.data == null || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: SizedBox.shrink()),
          );
        }

        final metadata = snapshot.data!;
        final videoId = metadata.extras?['ytid'];

        // Create YoutubePlayer widget
        final youtubePlayer = _youtubeController != null && _isVideoInitialized
            ? YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
                progressIndicatorColor: Theme.of(context).colorScheme.primary,
                progressColors: ProgressBarColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  handleColor: Theme.of(context).colorScheme.primary,
                ),
                onReady: () {
                  print('YouTube player is ready');
                },
                onEnded: (metaData) {
                  audioHandler.skipToNext();
                  final newVideoId =
                      audioHandler.mediaItem.value?.extras?['ytid'];
                  if (newVideoId != null && _youtubeController != null) {
                    _youtubeController!.load(newVideoId);
                  }
                },
              )
            : null;

        return YoutubePlayerBuilder(
          player: youtubePlayer ??
              YoutubePlayer(
                controller: YoutubePlayerController(
                  initialVideoId: '',
                  flags: const YoutubePlayerFlags(autoPlay: false),
                ),
              ),
          builder: (context, player) {
            return GestureDetector(
              onVerticalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                // Swipe down to dismiss
                if (details.primaryVelocity! > 200) {
                  Navigator.pop(context);
                }
                // Swipe up to show queue
                if (details.primaryVelocity! < -200) {
                  _showQueueSheet(context);
                }
              },
              child: Scaffold(
                extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  splashColor: Colors.white,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  if (videoId != null && _isVideoInitialized)
                    ValueListenableBuilder<bool>(
                      valueListenable: isVideoModeNotifier,
                      builder: (context, isVideo, child) {
                        return Container(
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_isVideoMode) _toggleVideoMode();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isVideo
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.music_note,
                                        size: 16,
                                        color: !isVideo
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Audio',
                                        style: TextStyle(
                                          color: !isVideo
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (!_isVideoMode) _toggleVideoMode();
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isVideo
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        size: 16,
                                        color: isVideo
                                            ? Colors.black
                                            : Colors.white,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Video',
                                        style: TextStyle(
                                          color: isVideo
                                              ? Colors.black
                                              : Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
              body: Stack(
                children: [
                  // Spotify-like Background Effect
                  ValueListenableBuilder<Color?>(
                    valueListenable: _dominantColorNotifier,
                    builder: (context, color, _) {
                      return _buildSpotifyBackground(context, metadata, color);
                    },
                  ),

                  // Main Content
                  SafeArea(
                    child: isLargeScreen
                        ? DesktopLayout(
                            metadata: metadata,
                            size: size,
                            adjustedIconSize: adjustedIconSize,
                            adjustedMiniIconSize: adjustedMiniIconSize,
                            youtubeController: _youtubeController,
                            youtubePlayer: youtubePlayer,
                            isVideoMode: _isVideoMode,
                          )
                        : MobileLayout(
                            metadata: metadata,
                            size: size,
                            adjustedIconSize: adjustedIconSize,
                            adjustedMiniIconSize: adjustedMiniIconSize,
                            isLargeScreen: isLargeScreen,
                            youtubeController: _youtubeController,
                            youtubePlayer: youtubePlayer,
                            isVideoMode: _isVideoMode,
                            onQueueButtonPressed: () => _showQueueSheet(context),
                          ),
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

  Widget _buildSpotifyBackground(
      BuildContext context, MediaItem metadata, Color? dominantColor) {
    return Stack(
      children: [
        // Solid color background first for instant display
        Positioned.fill(
          child: Container(
            color: dominantColor ?? Colors.black.withOpacity(0.85),
          ),
        ),

        // Image background with blur (loads after)
        if (metadata.artUri != null)
          Positioned.fill(
            child: Transform.scale(
              scale: 1.4, // Crop/zoom the background image
              child: Image.network(
                _getBestImageUrl(metadata) ?? metadata.artUri.toString(),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) {
                    return child;
                  }
                  return Container(
                      color: dominantColor ?? Colors.black.withOpacity(0.85));
                },
                errorBuilder: (context, error, stackTrace) => Container(
                    color: dominantColor ?? Colors.black.withOpacity(0.85)),
              ),
            ),
          ),

        if (metadata.artUri != null)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),
          ),

        // Gradient overlay
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  (dominantColor ?? Colors.black).withOpacity(0.8),
                  Colors.black.withOpacity(0.9),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
