import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/mobile_ui/queue_sheet.dart';
import 'package:j3tunes/utilities/mediaitem.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:j3tunes/models/position_data.dart';
import 'package:j3tunes/utilities/formatter.dart';

// Global cache for now playing colors
final Map<String, Color> _nowPlayingColorCache = {};

/// A dedicated panel on the right for desktop layouts, showing the currently
/// playing song, album art, controls, queue, and lyrics.
class DesktopNowPlayingPanel extends StatefulWidget {
  const DesktopNowPlayingPanel({super.key});

  @override
  State<DesktopNowPlayingPanel> createState() => _DesktopNowPlayingPanelState();
}

class _DesktopNowPlayingPanelState extends State<DesktopNowPlayingPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ScrollController _queueScrollController;
  final ValueNotifier<Color?> _dominantColorNotifier =
      ValueNotifier<Color?>(null);
  String? _dominantColorImageUrl;
  bool _isDragging = false;
  double _dragValue = 0;
  // Removed YoutubePlayerController, _isVideoInitialized, _currentVideoId, _isVideoMode

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _queueScrollController = ScrollController();
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
      // Removed videoId initialization
    }

    // Listen to mediaItem changes for color init
    audioHandler.mediaItem.listen((mediaItem) {
      if (mediaItem != null) {
        final imageUrl = _getBestImageUrl(mediaItem);
        if (imageUrl != null && imageUrl != _dominantColorImageUrl) {
          _updateDominantColor(imageUrl);
        }
        // Removed videoId initialization
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queueScrollController.dispose();
    _dominantColorNotifier.dispose(); // Dispose the notifier
    // Removed _youtubeController?.dispose();
    super.dispose();
  }

  // Helper function to get the best quality image URL
  String? _getBestImageUrl(MediaItem mediaItem) {
    // Priority: highResImage > artUri > lowResImage
    final ytid = mediaItem.extras?['ytid']?.toString();
    final highResImage = mediaItem.extras?['highResImage']?.toString();
    final artUri = mediaItem.artUri?.toString();
    final lowResImage = mediaItem.extras?['lowResImage']?.toString();

    if (highResImage != null &&
        highResImage.isNotEmpty &&
        highResImage != 'null' &&
        highResImage.startsWith('http')) {
      return highResImage;
    }
    if (artUri != null &&
        artUri.isNotEmpty &&
        artUri != 'null' &&
        artUri.startsWith('http')) {
      return artUri;
    }
    if (lowResImage != null &&
        lowResImage.isNotEmpty &&
        lowResImage != 'null' &&
        lowResImage.startsWith('http')) {
      return lowResImage;
    }

    // If all else fails, construct a reliable URL from the video ID
    if (ytid != null && ytid.isNotEmpty) {
      return 'https://i.ytimg.com/vi/$ytid/hqdefault.jpg';
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
  // Removed _initializeVideoPlayer and _toggleVideoMode methods

  Widget _buildExtraControls(
      BuildContext context, MediaItem metadata) {
    final currentSong = mediaItemToMap(metadata);
    final isLiked = metadata.extras?['isLiked'] ?? false;

    Widget buildActionButton({
      required IconData icon,
      required String tooltip,
      required VoidCallback onPressed,
      Color? activeColor,
    }) {
      return IconButton(
        icon: Icon(icon),
        iconSize: 24,
        color: activeColor ?? Colors.white.withOpacity(0.8),
        tooltip: tooltip,
        onPressed: onPressed,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildActionButton(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            tooltip: 'Like',
            onPressed: () {
              // Assumes a 'toggleLike' custom action exists in your audio handler
              // that updates the mediaItem's extras.
              audioHandler.customAction('toggleLike', {'song': currentSong});
            },
            activeColor: isLiked ? Colors.redAccent : null,
          ),
          buildActionButton(
            icon: Icons.radio,
            tooltip: 'Start Radio',
            onPressed: () =>
                audioHandler.customAction('startRadio', {'song': currentSong}),
          ),
          buildActionButton(
            icon: Icons.download_outlined,
            tooltip: 'Download',
            onPressed: () {
              // Assumes a 'download' custom action exists in your audio handler.
              audioHandler.customAction('download', {'song': currentSong});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Starting download...'),
                  behavior: SnackBarBehavior.floating,
                  width: 200,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // A generic dark background that matches the playing state's vibe.
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey[900]!.withOpacity(0.6),
                  Colors.black.withOpacity(0.95),
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),
          // The content for the empty state.
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_note_outlined,
                  size: 80,
                  color: Colors.white.withOpacity(0.4),
                ),
                const SizedBox(height: 20),
                Text(
                  'Nothing Playing',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Songs you play will appear here',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
        if (snapshot.data == null || !snapshot.hasData) {
          return _buildEmptyState(context);
        }

        final metadata = snapshot.data!;
        final currentSong = mediaItemToMap(metadata);
        final String title = metadata.title;
        final String artist = metadata.artist ?? '';
        final String albumArtUrl = metadata.artUri?.toString() ?? '';

        // No YoutubePlayerBuilder needed if video functionality is removed
        return Stack(
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
              child: Column(
                children: [
                  // Use a Flexible instead of Expanded for the top part,
                  // and wrap its content in a SingleChildScrollView to prevent overflow.
                  Flexible(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Always show album art, no video player
                            Container(
                              width: 150,
                              height: 150,
                              clipBehavior: Clip.antiAlias,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8.0),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 2.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: albumArtUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: albumArtUrl,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const Center(
                                          child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                              color: Colors.grey[800],
                                              child: const Icon(Icons.album,
                                                  size: 100,
                                                  color: Colors.white54)),
                                    )
                                  : Container(
                                      color: Colors.grey[800],
                                      child: const Icon(Icons.album,
                                          size: 100, color: Colors.white54)),
                            ),
                            const SizedBox(height: 24),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    artist,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                            color: Colors.white.withOpacity(0.8)),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            // Progress Bar
                            StreamBuilder<PositionData>(
                              stream: audioHandler.positionDataStream,
                              builder: (context, snapshot) {
                                final hasData =
                                    snapshot.hasData && snapshot.data != null;
                                final positionData = hasData
                                    ? snapshot.data!
                                    : PositionData(
                                        Duration.zero, Duration.zero, Duration.zero);

                                final maxDuration =
                                    positionData.duration.inSeconds > 0
                                        ? positionData.duration.inSeconds.toDouble()
                                        : 1.0;
                                final currentValue = _isDragging
                                    ? _dragValue
                                    : positionData.position.inSeconds.toDouble();

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 12.0),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SliderTheme(
                                        data: SliderTheme.of(context).copyWith(
                                          activeTrackColor:
                                              Theme.of(context).colorScheme.primary,
                                          inactiveTrackColor: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.2),
                                          thumbColor:
                                              Theme.of(context).colorScheme.primary,
                                          overlayColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.2),
                                          thumbShape:
                                              const RoundSliderThumbShape(
                                                  enabledThumbRadius: 6),
                                          trackHeight: 4.0,
                                        ),
                                        child: Slider(
                                          value: currentValue.clamp(0.0, maxDuration),
                                          max: maxDuration,
                                          onChanged: hasData ? (value) { setState(() { _isDragging = true; _dragValue = value; }); } : null,
                                          onChangeEnd: hasData ? (value) { audioHandler.seek(Duration(seconds: value.toInt())); setState(() { _isDragging = false; }); } : null,
                                        ),
                                      ),
                                      _buildPositionRow(context,
                                          positionData.position, positionData.duration),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            // Controls
                            StreamBuilder<PlaybackState>(
                              stream: audioHandler.playbackState,
                              builder: (context, snapshot) {
                                return _buildControls(context, snapshot.data);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Queue and Lyrics (expandable)
                  Expanded(
                    child: Column(
                      children: [
                        TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Queue'),
                            Tab(text: 'Lyrics'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              Theme(
                                data: Theme.of(context).copyWith(
                                  // Make the Card background transparent
                                  cardColor: Colors.transparent,
                                  // Remove shadow which can look like a line
                                  cardTheme: const CardThemeData(
                                    elevation: 0,
                                  ),
                                  // Hide any Divider widget which might be the top line
                                  dividerTheme: const DividerThemeData(
                                      color: Colors.transparent, thickness: 0),
                                ),
                                child: QueueSheet(
                                  scrollController: _queueScrollController,
                                  isTransparent: true,
                                ),
                              ),
                              _buildLyricsView(currentSong),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, PlaybackState? playbackState) {
    final playing = playbackState?.playing ?? false;
    final processingState = playbackState?.processingState;
    final shuffleMode = playbackState?.shuffleMode ?? AudioServiceShuffleMode.none;
    final repeatMode = playbackState?.repeatMode ?? AudioServiceRepeatMode.none;

    final activeColor = Theme.of(context).colorScheme.primary;
    const iconSize = 36.0; // For prev/next
    const playIconSize = 42.0; // For play/pause

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            iconSize: 24,
            color: shuffleMode == AudioServiceShuffleMode.all
                ? activeColor
                : Colors.white,
            onPressed: () {
              final currentShuffleMode =
                  audioHandler.playbackState.value.shuffleMode;
              audioHandler.setShuffleMode(
                currentShuffleMode == AudioServiceShuffleMode.all
                    ? AudioServiceShuffleMode.none
                    : AudioServiceShuffleMode.all,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: iconSize,
            color: Colors.white,
            onPressed: audioHandler.skipToPrevious,
          ),
          if (processingState == AudioProcessingState.loading ||
              processingState == AudioProcessingState.buffering)
            Container(
              width: 64.0,
              height: 64.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Center(child: CircularProgressIndicator(color: Colors.black)),
            )
          else
            Container(
              width: 64.0,
              height: 64.0,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(playing ? Icons.pause : Icons.play_arrow,
                    color: Colors.black),
                iconSize: playIconSize,
                onPressed: playing ? audioHandler.pause : audioHandler.play,
              ),
            ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            iconSize: iconSize,
            color: Colors.white,
            onPressed: audioHandler.skipToNext,
          ),
          IconButton(
            icon: Icon(repeatMode == AudioServiceRepeatMode.one
                ? Icons.repeat_one
                : Icons.repeat),
            iconSize: 24,
            color:
                repeatMode != AudioServiceRepeatMode.none ? activeColor : Colors.white,
            onPressed: () {
              // Cycle through: none -> all -> one
              final current = audioHandler.playbackState.value.repeatMode;
              final next = current == AudioServiceRepeatMode.none
                  ? AudioServiceRepeatMode.all
                  : (current == AudioServiceRepeatMode.all
                      ? AudioServiceRepeatMode.one
                      : AudioServiceRepeatMode.none);
              audioHandler.setRepeatMode(next);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPositionRow(
    BuildContext context,
    Duration position,
    Duration duration,
  ) {
    final positionText = formatDuration(position.inSeconds);
    final durationText = formatDuration(duration.inSeconds);

    final textStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.white.withOpacity(0.8));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: textStyle),
          Text(durationText, style: textStyle),
        ],
      ),
    );
  }

  Widget _buildLyricsView(Map<String, dynamic>? currentSong) {
    if (currentSong == null) {
      return const Center(child: Text('No song playing'));
    }

    final artist = currentSong['artist'] as String?;
    final title = currentSong['title'] as String?;

    if (artist == null || title == null) {
      return const Center(child: Text('Lyrics not available.'));
    }

    return FutureBuilder<String?>(
      future: getSongLyrics(artist, title),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Lyrics not available for this song.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            snapshot.data!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        );
      },
    );
  }

  Widget _buildSpotifyBackground(
      BuildContext context, MediaItem metadata, Color? dominantColor) {
    final imageUrl = _getBestImageUrl(metadata);
    final bgColor = dominantColor ?? Colors.black.withOpacity(0.85);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Base layer: A blurred version of the album art.
        if (imageUrl != null)
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              // If the image fails to load, show a solid color background.
              errorBuilder: (context, error, stackTrace) {
                return Container(color: bgColor);
              },
            ),
          )
        else
          // If no image is available at all, just use the solid color.
          Container(color: bgColor),

        // Gradient overlay to create the desired atmospheric effect and ensure
        // text on top is readable.
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                bgColor.withOpacity(0.6),
                Colors.black.withOpacity(0.95),
              ],
              stops: const [0.0, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}
