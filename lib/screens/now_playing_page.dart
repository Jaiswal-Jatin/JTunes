import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/spinner.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'dart:ui';
import 'package:j3tunes/API/musify.dart';
import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/models/position_data.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_bottom_sheet.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/formatter.dart';
import 'package:j3tunes/utilities/mediaitem.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/marque.dart';
import 'package:j3tunes/widgets/playback_icon_button.dart';
import 'package:j3tunes/widgets/song_artwork.dart';

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
      final imageUrl = currentMediaItem.artUri?.toString();
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
        final imageUrl = mediaItem.artUri?.toString();
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
            hideControls: true,
            controlsVisibleAtStart: true,
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
            return Scaffold(
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  splashColor: Colors.transparent,
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
                        ? _DesktopLayout(
                            metadata: metadata,
                            size: size,
                            adjustedIconSize: adjustedIconSize,
                            adjustedMiniIconSize: adjustedMiniIconSize,
                            youtubeController: _youtubeController,
                            youtubePlayer: youtubePlayer,
                            isVideoMode: _isVideoMode,
                          )
                        : _MobileLayout(
                            metadata: metadata,
                            size: size,
                            adjustedIconSize: adjustedIconSize,
                            adjustedMiniIconSize: adjustedMiniIconSize,
                            isLargeScreen: isLargeScreen,
                            youtubeController: _youtubeController,
                            youtubePlayer: youtubePlayer,
                            isVideoMode: _isVideoMode,
                          ),
                  ),
                ],
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
            child: Image.network(
              metadata.artUri.toString(),
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

class _DesktopLayout extends StatelessWidget {
  const _DesktopLayout({
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

class _MobileLayout extends StatelessWidget {
  const _MobileLayout({
    required this.metadata,
    required this.size,
    required this.adjustedIconSize,
    required this.adjustedMiniIconSize,
    required this.isLargeScreen,
    required this.youtubeController,
    required this.youtubePlayer,
    required this.isVideoMode,
  });

  final MediaItem metadata;
  final Size size;
  final double adjustedIconSize;
  final double adjustedMiniIconSize;
  final bool isLargeScreen;
  final YoutubePlayerController? youtubeController;
  final YoutubePlayer? youtubePlayer;
  final bool isVideoMode;

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
          ),
          const SizedBox(height: 2),
        ],
      ],
    );
  }
}

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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_radius),
          child: SizedBox(
            width: imageSize,
            height: imageSize,
            child: ValueListenableBuilder<CardDisplayMode>(
              valueListenable: cardModeNotifier,
              builder: (context, mode, child) {
                return _buildCardContent(imageSize, _radius, lyricsTextStyle, mode);
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContent(double imageSize, double radius,
      TextStyle lyricsTextStyle, CardDisplayMode mode) {
    switch (mode) {
      case CardDisplayMode.artwork:
        return SongArtworkWidget(
          metadata: widget.metadata,
          size: imageSize,
          errorWidgetIconSize: widget.size.width / 8,
          borderRadius: radius,
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
                Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.8),
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

class QueueListView extends StatelessWidget {
  const QueueListView({super.key});

  @override
  Widget build(BuildContext context) {
    final _textColor = Colors.white.withOpacity(0.9);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            context.l10n!.playlist,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: activePlaylist['list'].isEmpty
              ? Center(
                  child: Text(
                    context.l10n!.noSongsInQueue,
                    style: TextStyle(color: _textColor),
                  ),
                )
              : ListView.builder(
                  itemCount: activePlaylist['list'].length,
                  itemBuilder: (context, index) {
                    final borderRadius = getItemBorderRadius(
                      index,
                      activePlaylist['list'].length,
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: borderRadius,
                      ),
                      child: SongBar(
                        activePlaylist['list'][index],
                        false,
                        onPlay: () {
                          audioHandler.playPlaylistSong(songIndex: index);
                        },
                        backgroundColor: Colors.transparent,
                        borderRadius: borderRadius,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class MarqueeTextWidget extends StatelessWidget {
  const MarqueeTextWidget({
    super.key,
    required this.text,
    required this.fontColor,
    required this.fontSize,
    required this.fontWeight,
  });

  final String text;
  final Color fontColor;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    return MarqueeWidget(
      backDuration: const Duration(seconds: 1),
      child: Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: fontColor,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.5),
              offset: const Offset(0, 1),
              blurRadius: 3,
            ),
          ],
        ),
      ),
    );
  }
}

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
                  MarqueeTextWidget(
                    text: metadata.artist!,
                    fontColor: Colors.white.withOpacity(0.8),
                    fontSize: screenHeight * 0.017,
                    fontWeight: FontWeight.w500,
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

class PositionSlider extends StatefulWidget {
  const PositionSlider({
    super.key,
    this.youtubeController,
    this.isVideoMode = false,
  });

  final YoutubePlayerController? youtubeController;
  final bool isVideoMode;

  @override
  State<PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends State<PositionSlider> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: widget.isVideoMode && widget.youtubeController != null
          ? _buildVideoSlider()
          : _buildAudioSlider(),
    );
  }

  Widget _buildVideoSlider() {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: widget.youtubeController!,
      builder: (context, value, child) {
        final position = value.position;
        final duration = value.metaData.duration;
        final maxDuration =
            duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
        final currentValue =
            _isDragging ? _dragValue : position.inSeconds.toDouble();

        return _buildSliderWidget(
          currentValue,
          maxDuration,
          position,
          duration,
          onChanged: (val) {
            setState(() {
              _isDragging = true;
              _dragValue = val;
            });
          },
          onChangeEnd: (val) {
            widget.youtubeController!.seekTo(Duration(seconds: val.toInt()));
            setState(() {
              _isDragging = false;
            });
          },
        );
      },
    );
  }

  Widget _buildAudioSlider() {
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream.distinct(),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data != null;
        final positionData = hasData
            ? snapshot.data!
            : PositionData(Duration.zero, Duration.zero, Duration.zero);

        final maxDuration = positionData.duration.inSeconds > 0
            ? positionData.duration.inSeconds.toDouble()
            : 1.0;
        final currentValue = _isDragging
            ? _dragValue
            : positionData.position.inSeconds.toDouble();

        return _buildSliderWidget(
          currentValue,
          maxDuration,
          positionData.position,
          positionData.duration,
          onChanged: hasData
              ? (value) {
                  setState(() {
                    _isDragging = true;
                    _dragValue = value;
                  });
                }
              : null,
          onChangeEnd: hasData
              ? (value) {
                  audioHandler.seek(Duration(seconds: value.toInt()));
                  setState(() {
                    _isDragging = false;
                  });
                }
              : null,
        );
      },
    );
  }

  Widget _buildSliderWidget(
    double currentValue,
    double maxDuration,
    Duration position,
    Duration duration, {
    ValueChanged<double>? onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            trackHeight: 3,
          ),
          child: Slider(
            value: currentValue.clamp(0.0, maxDuration),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            max: maxDuration,
          ),
        ),
        _buildPositionRow(context, position, duration),
      ],
    );
  }

  Widget _buildPositionRow(
    BuildContext context,
    Duration position,
    Duration duration,
  ) {
    final positionText = formatDuration(position.inSeconds);
    final durationText = formatDuration(duration.inSeconds);

    final textStyle = TextStyle(
      fontSize: 15,
      color: Colors.white.withOpacity(0.8),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: textStyle),
          Text(durationText, style: textStyle),
        ],
      ),
    );
  }
}

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

class BottomActionsRow extends StatelessWidget {
  const BottomActionsRow({
    super.key,
    required this.context,
    required this.audioId,
    required this.metadata,
    required this.iconSize,
    required this.isLargeScreen,
  });

  final BuildContext context;
  final dynamic audioId;
  final MediaItem metadata;
  final double iconSize;
  final bool isLargeScreen;

  @override
  Widget build(BuildContext context) {
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    final songOfflineStatus =
        ValueNotifier<bool>(isSongAlreadyOffline(audioId));

    final _primaryColor = Colors.white;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: [
        _buildOfflineButton(songOfflineStatus, _primaryColor),
        if (!offlineMode.value) _buildAddToPlaylistButton(_primaryColor),
        if (activePlaylist['list'].isNotEmpty && !isLargeScreen)
          _buildQueueButton(context, _primaryColor),
        if (!offlineMode.value) ...[
          _buildSleepTimerButton(context, _primaryColor),
          _buildLikeButton(songLikeStatus, _primaryColor),
        ],
      ],
    );
  }

  Widget _buildOfflineButton(ValueNotifier<bool> status, Color primaryColor) {
    return ValueListenableBuilder<bool>(
      valueListenable: status,
      builder: (_, value, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              value
                  ? FluentIcons.checkmark_circle_24_filled
                  : FluentIcons.arrow_download_24_filled,
              color: primaryColor,
            ),
            iconSize: iconSize,
            onPressed: () {
              if (value) {
                removeSongFromOffline(audioId);
              } else {
                makeSongOffline(mediaItemToMap(metadata));
              }
              status.value = !status.value;
            },
          ),
        );
      },
    );
  }

  Widget _buildAddToPlaylistButton(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(Icons.add, color: primaryColor),
        iconSize: iconSize,
        onPressed: () {
          showAddToPlaylistDialog(context, mediaItemToMap(metadata));
        },
      ),
    );
  }

  Widget _buildQueueButton(BuildContext context, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(FluentIcons.apps_list_24_filled, color: primaryColor),
        iconSize: iconSize,
        onPressed: () {
          showCustomBottomSheet(
            context,
            ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: commonListViewBottmomPadding,
              itemCount: activePlaylist['list'].length,
              itemBuilder: (BuildContext context, int index) {
                final borderRadius = getItemBorderRadius(
                  index,
                  activePlaylist['list'].length,
                );
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: borderRadius,
                  ),
                  child: SongBar(
                    activePlaylist['list'][index],
                    false,
                    onPlay: () {
                      audioHandler.playPlaylistSong(songIndex: index);
                    },
                    backgroundColor: Colors.transparent,
                    borderRadius: borderRadius,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSleepTimerButton(BuildContext context, Color primaryColor) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: sleepTimerNotifier,
      builder: (_, value, __) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              value != null
                  ? FluentIcons.timer_24_filled
                  : FluentIcons.timer_24_regular,
              color: primaryColor,
            ),
            iconSize: iconSize,
            onPressed: () {
              if (value != null) {
                audioHandler.cancelSleepTimer();
                sleepTimerNotifier.value = null;
                showToast(
                  context,
                  context.l10n!.sleepTimerCancelled,
                  duration: const Duration(seconds: 1, milliseconds: 500),
                );
              } else {
                _showSleepTimerDialog(context);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildLikeButton(ValueNotifier<bool> status, Color primaryColor) {
    return ValueListenableBuilder<bool>(
      valueListenable: status,
      builder: (_, value, __) {
        final icon =
            value ? FluentIcons.heart_24_filled : FluentIcons.heart_24_regular;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: primaryColor),
            iconSize: iconSize,
            onPressed: () {
              updateSongLikeStatus(audioId, !status.value);
              status.value = !status.value;
            },
          ),
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final duration = sleepTimerNotifier.value ?? Duration.zero;
        var hours = duration.inMinutes ~/ 60;
        var minutes = duration.inMinutes % 60;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              title: Text(
                context.l10n!.setSleepTimer,
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n!.selectDuration,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n!.hours,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              if (hours > 0) {
                                setState(() {
                                  hours--;
                                });
                              }
                            },
                          ),
                          Text(
                            '$hours',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                hours++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n!.minutes,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              if (minutes > 0) {
                                setState(() {
                                  minutes--;
                                });
                              }
                            },
                          ),
                          Text(
                            '$minutes',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                minutes++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.l10n!.cancel,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final duration = Duration(hours: hours, minutes: minutes);
                    if (duration.inSeconds > 0) {
                      audioHandler.setSleepTimer(duration);
                      showToast(
                        context,
                        context.l10n!.sleepTimerSet,
                        duration: const Duration(seconds: 1, milliseconds: 500),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n!.setTimer),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
