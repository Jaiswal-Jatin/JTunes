// ignore_for_file: deprecated_member_use, omit_local_variable_types, unnecessary_lambdas, unawaited_futures, unused_field, unused_import, directives_ordering, require_trailing_commas, prefer_final_in_for_each, unused_element_parameter, prefer_if_elements_to_conditional_expressions

import 'package:carousel_slider/carousel_slider.dart';
import 'package:j3tunes/services/youtube_service.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:audio_service/audio_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/playlist_page.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:flutter/scheduler.dart'; // Added for SchedulerBinding
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/services/update_manager.dart'; // Added for checkAppUpdates
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/playlist_cube.dart';
import 'package:j3tunes/widgets/section_header.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/spinner.dart';
import 'package:j3tunes/widgets/user_profile_card.dart';
import 'dart:math';
import 'package:j3tunes/widgets/shimmer_widgets.dart';
import 'dart:ui';

import 'package:j3tunes/widgets/banner_ad_widget.dart';
// Helper: filter only real songs (duration <= 5min, not mashup/remix/etc)
bool isValidSong(Video song) {
  final duration = song.duration?.inSeconds ?? 0;
  if (duration < 120 || duration > 420) return false; // only 2-7 min

  final title = song.title.toLowerCase();
  final desc = song.description.toLowerCase();

  // Block mashup, remix, mix, compilation, nonstop, hour, long, medley, etc.
  const nonSongKeywords = [
    'remix',
    'mashup',
    'nonstop',
    'mix',
    'full album',
    'compilation',
    'medley',
    'continuous',
    'long version',
    'hour',
    'hours',
    'podcast',
    'session',
    'radio',
    'instrumental',
    'background',
    'study',
    'focus',
    'lofi',
    'billion',
    'billion views',
    'billionaires',
    'invest',
    'sector',
    'news',
    'update',
    'future',
    'cities',
    'cream',
    'moisturizer',
    'workout'
  ];

  for (final word in nonSongKeywords) {
    if (title.contains(word) || desc.contains(word)) return false;
  }
  return true;
}

// Helper to convert Video to Map for UI widgets
Map<String, dynamic> videoToMap(Video v) {
  String image = v.thumbnails.highResUrl.isNotEmpty
      ? v.thumbnails.highResUrl
      : v.thumbnails.standardResUrl.isNotEmpty
          ? v.thumbnails.standardResUrl
          : v.thumbnails.mediumResUrl.isNotEmpty
              ? v.thumbnails.mediumResUrl
              : v.thumbnails.lowResUrl;

  // Fallback to local asset if all are empty or blank
  if (image.isEmpty) {
    image = 'assets/images/JTunes.png';
  }

  return {
    'ytid': v.id.value,
    'title': v.title,
    'image': image,
    'artist': v.author,
    'description': v.description,
    // No 'list' or 'video' key here
  };
}

// Helper to safely convert Map to Map<String, dynamic>
Map<String, dynamic> safeMapConvert(dynamic map) {
  if (map == null) return <String, dynamic>{};
  if (map is Map<String, dynamic>) return map;
  if (map is Map) {
    return Map<String, dynamic>.from(map);
  }
  return <String, dynamic>{};
}

// Helper to safely convert List to List<Map<String, dynamic>>
List<Map<String, dynamic>> safeListConvert(dynamic list) {
  if (list == null) return <Map<String, dynamic>>[];
  if (list is List<Map<String, dynamic>>) return list;
  if (list is List) {
    return list.map((item) => safeMapConvert(item)).toList();
  }
  return <Map<String, dynamic>>[];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with AutomaticKeepAliveClientMixin {
  static bool _updateCheckPerformed = false; // Flag to ensure update check runs only once

  // Keep the page alive to avoid rebuilding
  String? _getRandomPlaylistImage(List<dynamic> songs) {
    if (songs.isEmpty) return null;
    final randomSong = songs[Random().nextInt(songs.length)];
    final songMap = safeMapConvert(randomSong);
    return songMap['artUri'] as String? ??
        songMap['image'] as String? ??
        songMap['highResImage'] as String? ??
        songMap['lowResImage'] as String?;
  }

  @override
  bool get wantKeepAlive => true;

  Future<List<dynamic>>? _suggestedSongsFuture;
  // Cache futures to avoid repeated API calls
  Future<List<dynamic>>? _suggestedPlaylistsFuture;
  Future<List<dynamic>>? _likedPlaylistsFuture;
  Future<dynamic>? _trendingSongsFuture;
  Future<dynamic>? _popSongsFuture;
  Future<dynamic>? _rockSongsFuture;
  Future<dynamic>? _bollywoodSongsFuture;
  Future<dynamic>? _punjabSongsFuture;
  Future<dynamic>? _marathiSongsFuture;
  Future<dynamic>? _teluguSongsFuture;
  Future<dynamic>? _tamilSongsFuture;
  Future<dynamic>? _kpopSongsFuture;
  Future<List<dynamic>>? _recentlyPlayedFuture;
  Future<dynamic>? _internationalSongsFuture;

  @override
  void initState() {
    super.initState();
    _initializeFutures();
    audioHandler.mediaItem.listen(_onMediaItemChanged);
    currentLikedPlaylistsLength.addListener(_refreshLikedPlaylists);
    _onMediaItemChanged(audioHandler.mediaItem.value);

    // Trigger update check only after the Home screen is fully loaded
    if (!isFdroidBuild && !_updateCheckPerformed) {
      SchedulerBinding.instance.addPostFrameCallback((_) async {
        if (mounted) { // Ensure the widget is still mounted before showing dialogs
          await checkAppUpdates(); // Pass context
          _updateCheckPerformed = true;
        }
      });
    }
  }

  @override
  void dispose() {
    currentLikedPlaylistsLength.removeListener(_refreshLikedPlaylists);
    super.dispose();
  }

  void _refreshLikedPlaylists() {
    if (mounted) {
      // Re-initialize liked playlists to reflect changes
      _initializeLikedPlaylists();
    }
  }

  void _onMediaItemChanged(MediaItem? mediaItem) {
    if (!mounted) return;
    final songId = mediaItem?.extras?['ytid'] as String?;
    if (songId != null && songId.isNotEmpty) {
      if (mounted) {
        setState(() {
          _suggestedSongsFuture = getNextRecommendedSongs(songId, count: 15);
        });
      }
    }
  }

  void _initializeFutures() {
    // User-provided playlists with only links and titles, no static images
    final userPlaylists = [
      {
        'ytid':
            'https://www.youtube.com/watch?v=sUf2PtEZris&list=PL4fGSI1pDJn4pTWyM3t61lOyZ6_4jcNOw',
        'title': 'Playlist 1',
        'list': <Map<String, dynamic>>[],
      },
      {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_n9Fbdw7e6ap-98_A-8JYBmPv64v-Uaq1g&playnext=1&index=1',
        'title': 'Playlist 2',
        'list': <Map<String, dynamic>>[],
      },
      {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_kjNBBWqyQ_Cy14B0P4xrcKgd39CRjXXKk&playnext=1&index=1',
        'title': 'Playlist 3',
        'list': <Map<String, dynamic>>[],
      },
      {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_l_Bj8rMsjkhFMMs-eLrA17_zjr9r6g_Eg&playnext=1&index=1',
        'title': 'Playlist 4',
        'list': <Map<String, dynamic>>[],
      },
      {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_m_cn307EUnwiDOgAsOMM27CHhuJCX2ygk&playnext=1&index=1',
        'title': 'Playlist 5',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_nlKphX00YtBNjlGZcmPifGNAPXUSjezNM&playnext=1&index=1',
        'title': 'Playlist 6',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_lBa7h-v-su4TAsDNvyelrswt9YYYU7x4g&playnext=1&index=1',
        'title': 'Playlist 7',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_kb7EBi6y3GrtJri4_ZH56Ms786DFEimbM&playnext=1&index=1',
        'title': 'Playlist 8',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_n41V9iqmjro6caBDuDD1E4eWs5yTb5_OY&playnext=1&index=1',
        'title': 'Playlist 9',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/watch?v=ziM_K-n6svk&list=OLAK5uy_lSTp1DIuzZBUyee3kDsXwPgP25WdfwB40',
        'title': 'Playlist 10',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/watch?v=yebNIHKAC4A&list=PL4fGSI1pDJn6puJdseH2Rt9sMvt9E2M4i',
        'title': 'Playlist 11',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_nLOvZAnN86K4f-fJ6tUi0xHUPBHLBBkVE&playnext=1&index=1',
        'title': 'Playlist 12',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_kWKAcJROkxDk9mOVmfDSv9cycK_-Ci2yA&playnext=1&index=1',
        'title': 'Playlist 13',
        'list': <Map<String, dynamic>>[],
      },
       {
        'ytid':
            'https://www.youtube.com/playlist?list=RDCLAK5uy_kiDNaS5nAXxdzsqFElFKKKs0GUEFJE26w&playnext=1&index=1',
        'title': 'Playlist 14',
        'list': <Map<String, dynamic>>[],
      },
        {
        'ytid':
            'https://www.youtube.com/watch?v=983bBbJx0Mk&list=PL4fGSI1pDJn5kI81J1fYWK5eZRl1zJ5kM',
        'title': 'Playlist 15',
        'list': <Map<String, dynamic>>[],
      },
    ];

    _suggestedPlaylistsFuture =
        Future.wait(userPlaylists.map((playlistMap) async {
      final yt = YoutubeExplode();
      final playlistUrl = playlistMap['ytid'] as String;

      PlaylistId playlistId;
      try {
        String? idString;
        // Handle both full URLs (e.g., ...?list=ID) and plain IDs.
        if (playlistUrl.startsWith('http')) {
          idString = Uri.parse(playlistUrl).queryParameters['list'];
        } else {
          idString = playlistUrl;
        }

        if (idString == null || idString.isEmpty) {
          throw ArgumentError('Could not extract playlist ID from URL.');
        }
        playlistId = PlaylistId(idString);
      } catch (e) {
        print('Error parsing playlist URL "$playlistUrl": $e');
        return {
          'ytid': playlistUrl,
          'title': 'Invalid Playlist',
          'image': null,
          'list': <Map<String, dynamic>>[],
        };
      }

      try {
        // Fetch playlist metadata and the first video concurrently for efficiency.
        final metadataFuture = yt.playlists.get(playlistId);
        final videosFuture = yt.playlists.getVideos(playlistId).take(10).toList(); // Fetch first 10

        final results = await Future.wait([metadataFuture, videosFuture]);

        final metadata = results[0] as Playlist;
        final videos = results[1] as List<Video>;

        if (videos.isEmpty) {
          // Handle case where playlist is empty
          return {
            'ytid': playlistId.value,
            'title': metadata.title,
            'image': null, // No image if no videos
            'list': <Map<String, dynamic>>[],
          };
        }

        // Pick a random video from the fetched batch.
        final randomVideo = videos[Random().nextInt(videos.length)];

        return {
          'ytid': playlistId.value,
          'title': metadata.title,
          'image': randomVideo.thumbnails.highResUrl,
          'list': <Map<String, dynamic>>[], // Keep song list empty for now.
        };
      } catch (e) {
        print('Error fetching playlist info for $playlistUrl: $e');
        return {
          'ytid': playlistUrl,
          'title': 'Failed to Load',
          'image': null,
          'list': <Map<String, dynamic>>[],
        };
      }
    }));

    // Initialize other futures with reduced delays for better UX
    _initializeOtherFutures();
  }

  void _initializeOtherFutures() {
    // Liked playlists from local
    _initializeLikedPlaylists();

    // Initialize song futures with staggered delays
    _recentlyPlayedFuture = getRecents();
    _initializeSongFutures();
  }

  void _initializeLikedPlaylists() {
    Future.delayed(Duration.zero, () async {
      if (mounted) {
        try {
          final likedIds = await getLikedPlaylists();
          final likedPlaylists = <Map<String, dynamic>>[];

          for (final id in likedIds) {
            try {
              final playlistData = await getPlaylistInfoForWidget(id);
              if (playlistData != null) {
                final safeSongMaps = safeListConvert(playlistData['list']);
                if (safeSongMaps.isNotEmpty) {
                  String image = _getRandomPlaylistImage(safeSongMaps) ??
                      playlistData['image'] ??
                      safeSongMaps.first['image'] ??
                      'assets/images/JTunes.png';
                  likedPlaylists.add({
                    'ytid': id,
                    'title': playlistData['title'] ?? 'Liked Playlist',
                    'image': image,
                    'list': safeSongMaps,
                  });
                }
              }
            } catch (e) {
              print('Error fetching liked playlist $id: $e');
            }
          }
          if (mounted) {
            setState(() {
              _likedPlaylistsFuture = Future.value(likedPlaylists);
            });
          }
        } catch (e) {
          print('Error loading liked playlists: $e');
        }
      }
    });
  }

  void _initializeSongFutures() {
    final songCategories = [
      {'name': 'trending songs 2025', 'delay': 10, 'future': 'trending'},
      {
        'name': 'kpop songs 2025 BTS Blackpink NewJeans',
        'delay': 15,
        'future': 'kpop'
      },
      {
        'name': 'international top songs 2025 english hits',
        'delay': 20,
        'future': 'international'
      },
      {'name': 'pop songs 2025', 'delay': 25, 'future': 'pop'},
      {'name': 'rock songs 2025', 'delay': 30, 'future': 'rock'},
      {'name': 'bollywood songs 2025', 'delay': 35, 'future': 'bollywood'},
      {'name': 'punjabi songs 2025', 'delay': 40, 'future': 'punjab'},
      {'name': 'marathi songs 2025', 'delay': 45, 'future': 'marathi'},
      {'name': 'telugu songs 2025', 'delay': 50, 'future': 'telugu'},
      {'name': 'tamil songs 2025', 'delay': 55, 'future': 'tamil'},
    ];

    for (final category in songCategories) {
      Future.delayed(Duration(milliseconds: category['delay'] as int),
          () async {
        if (mounted) {
          final yt = YoutubeService();
          final songs =
              await yt.searchVideos(category['name'] as String, maxResults: 50);
          final filtered = songs.where(isValidSong).take(12).toList();

          if (mounted) {
            setState(() {
              switch (category['future']) {
                case 'trending':
                  _trendingSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'kpop':
                  _kpopSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'international':
                  _internationalSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'pop':
                  _popSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'rock':
                  _rockSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'bollywood':
                  _bollywoodSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'punjab':
                  _punjabSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'marathi':
                  _marathiSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'telugu':
                  _teluguSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
                case 'tamil':
                  _tamilSongsFuture =
                      Future.value(filtered.map((v) => videoToMap(v)).toList());
                  break;
              }
            });
          }
        }
      });
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final playlistHeight = (screenHeight * 0.22).clamp(160.0, 200.0);

    final isLoading = _suggestedPlaylistsFuture == null ||
        _recentlyPlayedFuture == null ||
        (_suggestedSongsFuture == null && _trendingSongsFuture == null) ||
        _popSongsFuture == null ||
        _rockSongsFuture == null ||
        _bollywoodSongsFuture == null ||
        _punjabSongsFuture == null ||
        _marathiSongsFuture == null ||
        _teluguSongsFuture == null ||
        _tamilSongsFuture == null ||
        _kpopSongsFuture == null ||
        _internationalSongsFuture == null;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshContent,
          color: Theme.of(context).colorScheme.primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: isLoading
                ? const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      HomeHeaderShimmer(),
                      HomePlaylistSectionShimmer(title: 'Suggested Playlists'),
                      const _HomeRecentsSectionShimmer(),
                      const HomeSongSectionShimmer(title: 'Songs for You'),
                      HomeSongSectionShimmer(title: 'Bollywood Songs'),
                      HomeSongSectionShimmer(title: 'Punjabi Songs'),
                      HomeSongSectionShimmer(title: 'Marathi Songs'),
                      HomeSongSectionShimmer(title: 'Telugu Songs'),
                      HomeSongSectionShimmer(title: 'Tamil Songs'),
                      HomeSongSectionShimmer(title: 'K-Pop Hits'),
                      HomeSongSectionShimmer(title: 'Pop Music'),
                      HomeSongSectionShimmer(title: 'Rock'),
                      HomePlaylistSectionShimmer(title: 'Your Liked Playlists'),
                      SizedBox(height: 80),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header - reduced padding
                      _buildHeader(),

                      // Playlist Section with improved UI
                      RepaintBoundary(
                        child: _buildSuggestedPlaylists(playlistHeight),
                      ),

                      // Recently Played Section
                      RepaintBoundary(
                        child: _buildRecentlyPlayedSection(),
                      ),

                      // Ad Widget
                      const RepaintBoundary(
                        child: BannerAdWidget(),
                      ),

                      // Song sections with reduced spacing
                      ..._buildSongSections(),

                      // Liked Playlists at bottom with SAME UI as suggested playlists
                      if (_likedPlaylistsFuture != null) ...[
                        RepaintBoundary(
                          child: _buildLikedPlaylists(playlistHeight),
                        ),
                      ],

                     // Bottom Ad Widget
                    const RepaintBoundary(
                        child: BannerAdWidget(),
                      ),  

                      // Bottom padding for mini player
                      const SizedBox(height: 80), // Reduced from 100

                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Show shimmer while loading playlists (header always loads instantly, but shimmer for consistency)
    if (_suggestedPlaylistsFuture == null) {
      return const HomeHeaderShimmer();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ...existing code...
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  'Liked Songs',
                  Icons.favorite,
                  () {
                    NavigationManager.router.push('/library/userSongs/liked');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAccessButton(
                  'Downloaded',
                  Icons.download,
                  () {
                    NavigationManager.router.push('/library/userSongs/offline');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  'Suggested Songs',
                  Icons.auto_awesome,
                  () async {
                    if (_trendingSongsFuture != null) {
                      final snapshot = await _trendingSongsFuture;
                      if (snapshot is List && snapshot.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistPage(
                              playlistData: {
                                'title': 'Suggested Songs',
                                'list': snapshot.take(50).toList(),
                                'image': snapshot[0]['image'] ??
                                    'assets/images/JTunes.png',
                                'source': 'trending',
                              },
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButton(
      String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52, // Slightly reduced from 56
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 22, // Slightly reduced
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13, // Reduced from 14
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentlyPlayedSection() {
    return FutureBuilder<List<dynamic>>(
      future: _recentlyPlayedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting ||
            !snapshot.hasData ||
            snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final recentSongs =
            snapshot.data!.map((e) => safeMapConvert(e)).toList();
        if (recentSongs.isEmpty) return const SizedBox.shrink();

        // Take 6 songs for a 3x2 grid
        final songsToShow = recentSongs.take(6).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Recently Played', onSeeAll: () {
              NavigationManager.router.push('/library/userSongs/recents');
            }),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: songsToShow.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  mainAxisExtent: 52,
                ),
                itemBuilder: (context, index) {
                  final song = songsToShow[index];
                  return _buildRecentSongGridItem(song);
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }

  Widget _buildRecentSongGridItem(Map<String, dynamic> song) {
    final imageUrl =
        song['image'] ?? song['lowResImage'] ?? 'assets/images/JTunes.png';

    return GestureDetector(
      onTap: () => audioHandler.playSong(song),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 52,
              height: 52,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(4)),
                child: _buildImageWidget(imageUrl),
              ),
            ),
            const SizedBox(width: 10),
            _buildTitleWidget(song['title'] ?? 'Unknown Title'),
          ],
        ),
      ),
    );
  }

  // Enhanced playlist UI with better spacing and carousel support
  Widget _buildSuggestedPlaylists(double playlistHeight,
      {bool showOnlyLiked = false}) {
    final sectionTitle =
        showOnlyLiked ? 'Back to Favorites' : 'Suggested Playlists';
    final adjustedHeight =
        showOnlyLiked ? playlistHeight * 0.6 : playlistHeight;

    return FutureBuilder<List<dynamic>>(
      future: showOnlyLiked ? _likedPlaylistsFuture : _suggestedPlaylistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return HomePlaylistSectionShimmer(title: sectionTitle);
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildSuggestedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _buildErrorWidget(context);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final playlists = snapshot.data ?? [];
        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        return Column(
          children: [
            _buildSectionHeader(sectionTitle),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: adjustedHeight),
              child: _buildCarouselView(
                playlists,
                itemsNumber,
                adjustedHeight,
                showOnlyLiked: showOnlyLiked,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalList(
    List<dynamic> playlists,
    int itemCount,
    double height, {
    bool showOnlyLiked = false,
  }) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: showOnlyLiked ? 10 : 12, // Reduced padding for liked
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index];

        String? dynamicPlaylistImage = playlist['image'];
        if (playlist['list'] != null && playlist['list'].isNotEmpty) {
          dynamicPlaylistImage =
              _getRandomPlaylistImage(playlist['list']) ?? playlist['image'];
        }

        // Create modified playlist with dynamic image
        final modifiedPlaylist = Map<String, dynamic>.from(playlist);
        modifiedPlaylist['image'] = dynamicPlaylistImage;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showOnlyLiked ? 3 : 6, // Reduced spacing for liked
          ),
          child: SizedBox(
            width: height,
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(
                    playlistId: playlist['ytid'],
                    playlistData: showOnlyLiked
                        ? playlist
                        : null, // Pass data for liked playlists
                  ),
                ),
              ),
              child: _buildPlaylistCardWithOverlay(modifiedPlaylist, height),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCarouselView(
    List<dynamic> playlists,
    int itemCount,
    double height, {
    bool showOnlyLiked = false,
  }) {    
    final items = List.generate(itemCount, (index) {
        final playlist = playlists[index];
        final modifiedPlaylist = Map<String, dynamic>.from(playlist);

        if (modifiedPlaylist['list'] != null &&
            (modifiedPlaylist['list'] as List).isNotEmpty) {
          modifiedPlaylist['image'] =
              _getRandomPlaylistImage(modifiedPlaylist['list']) ??
                  modifiedPlaylist['image'];
        }

        return GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlaylistPage(
                playlistId: playlist['ytid'],
                playlistData: showOnlyLiked ? playlist : null,
              ),
            ),
          ),
          child: _buildPlaylistCardWithOverlay(modifiedPlaylist, height * 1.2),
        );
      });

    return CarouselSlider(
      items: items,
      options: CarouselOptions(
        height: height,
        autoPlay: true,
        enlargeCenterPage: true,
        viewportFraction: 0.8,
        aspectRatio: 16 / 9,
      ),
    );
  }

  // UPDATED: Now uses the same structure as suggested playlists
  Widget _buildLikedPlaylists(double playlistHeight) {
    if (_likedPlaylistsFuture == null) {
      return _buildLoadingWidget();
    }

    return FutureBuilder<List<dynamic>>(
      future: _likedPlaylistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildSectionHeader('Your Liked Playlists'),
              _buildLoadingWidget(),
            ],
          );
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildLikedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return const SizedBox.shrink();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final rawPlaylists = snapshot.data ?? [];
        final playlists =
            rawPlaylists.map((item) => safeMapConvert(item)).toList();
        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        if (playlists.isEmpty) {
          return const SizedBox.shrink();
        }

        // Use the same structure as suggested playlists
        return Column(
          children: [
            _buildSectionHeader('Your Liked Playlists'),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child: _buildCarouselView(
                playlists,
                itemsNumber,
                playlistHeight,
                showOnlyLiked: true, // This flag differentiates it
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildSongSections() {
    final sections = [
      {
        'title': 'Songs for You',
        'future': _suggestedSongsFuture ?? _trendingSongsFuture,
        'key': 'suggested_song'
      },
      {
        'title': 'Bollywood Songs',
        'future': _bollywoodSongsFuture,
        'key': 'bollywood_song'
      },
      {
        'title': 'Punjabi Songs',
        'future': _punjabSongsFuture,
        'key': 'punjabi_song'
      },
      {
        'title': 'Marathi Songs',
        'future': _marathiSongsFuture,
        'key': 'marathi_song'
      },
      {
        'title': 'Telugu Songs',
        'future': _teluguSongsFuture,
        'key': 'telugu_song'
      },
      {
        'title': 'Tamil Songs',
        'future': _tamilSongsFuture,
        'key': 'tamil_song'
      },
      {'title': 'K-Pop Hits', 'future': _kpopSongsFuture, 'key': 'k_pop_song'},
      {'title': 'Pop Music', 'future': _popSongsFuture, 'key': 'pop_song'},
      {'title': 'Rock Songs', 'future': _rockSongsFuture, 'key': 'rock_song'},
    ];

    return sections
        .where((section) => section['future'] != null)
        .map((section) => RepaintBoundary(
              child: _buildHorizontalSongsSectionWithSeeAll(
                section['title'] as String,
                section['future'] as Future<dynamic>,
                section['key'] as String,
              ),
            ))
        .toList();
  }

  Future<void> _refreshContent() async {
    setState(() {
      _suggestedPlaylistsFuture = null;
      _suggestedSongsFuture = null;
      _recentlyPlayedFuture = getRecents();
      _likedPlaylistsFuture = null;
      _trendingSongsFuture = null;
      _kpopSongsFuture = null;
      _internationalSongsFuture = null;
      _popSongsFuture = null;
      _rockSongsFuture = null;
      _bollywoodSongsFuture = null;
      _punjabSongsFuture = null;
      _marathiSongsFuture = null;
      _teluguSongsFuture = null;
      _tamilSongsFuture = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _initializeFutures();
    _onMediaItemChanged(audioHandler.mediaItem.value);
  }

  Widget _buildLoadingWidget() {
    return Container(
      height: 60,
      child: const Center(
        child: Spinner(),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Container(
      height: 60,
      child: Center(
        child: Text(
          'Error loading content',
          style: TextStyle(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4), // Reduced padding
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18, // Reduced font size
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              child: const Text('See All'),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalSongsSectionWithSeeAll(
    String title,
    Future<dynamic> future,
    String keyPrefix,
  ) {
    return FutureBuilder<dynamic>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return HomeSongSectionShimmer(title: title);
        }

        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }

        if (snapshot.hasError) {
          logger.log(
            'Error in _buildHorizontalSongsSection for $title',
            snapshot.error,
            snapshot.stackTrace,
          );
          return const SizedBox.shrink();
        }

        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data as List<dynamic>;
        if (data.isEmpty) return const SizedBox.shrink();

        // Patch: ensure every song has 'lowResImage' for SongBar
        final patchedData = data.map((item) {
          if (item is Map<String, dynamic>) {
            final patched = Map<String, dynamic>.from(item);
            if (patched['image'] != null) {
              patched['lowResImage'] = patched['image'];
            }
            return patched;
          }
          return item;
        }).toList();

        final int minSongs = 20;
        final int maxSongs = 30;
        final int showCount = patchedData.length < minSongs
            ? patchedData.length
            : (patchedData.length > maxSongs ? maxSongs : patchedData.length);

        return Column(
          children: [
            _buildSectionHeader(title, onSeeAll: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(
                    playlistData: {
                      'title': title,
                      'list': patchedData.take(maxSongs).toList(),
                      'image': patchedData.isNotEmpty
                          ? patchedData[0]['image'] ??
                              'assets/images/JTunes.png'
                          : 'assets/images/JTunes.png',
                      'source': 'auto',
                    },
                  ),
                ),
              );
            }),
            Container(
              height: 150, // Reduced height
              margin: const EdgeInsets.only(bottom: 12), // Reduced margin
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12), // Reduced padding
                itemCount: showCount,
                itemBuilder: (context, index) {
                  final item = patchedData[index] as Map<String, dynamic>;
                  final ytid = item['ytid'];
                  final songWithImage = Map<String, dynamic>.from(item);

                  String? img = songWithImage['artUri'] ??
                      songWithImage['image'] ??
                      songWithImage['highResImage'];
                  if (img == null || img.isEmpty)
                    img = 'assets/images/JTunes.png';
                  songWithImage['lowResImage'] = img;

                  return Container(
                    width: 110, // Reduced width
                    margin: const EdgeInsets.only(right: 8), // Reduced margin
                    child: RepaintBoundary(
                      key: ValueKey('${keyPrefix}_${ytid}'),
                      child: _buildSongCard(songWithImage),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSongCard(Map<String, dynamic> song) {
    return GestureDetector(
      onTap: () {
        audioHandler.playSong(song);
      },
      child: SizedBox(
        width: (MediaQuery.of(context).size.width / 3.8).clamp(100.0, 120.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Transform.scale(
                  scale: 1.4, // Crop/zoom all home page song images everywhere
                  child: Image.network(
                    song['lowResImage'] ?? song['image'] ?? '',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28, // Reduced size
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              song['title'] ?? 'Unknown Title',
              style: TextStyle(
                fontSize: 11, // Reduced font size
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // UPDATED PLAYLIST CARD METHOD - Now uses a random image from the playlist
  Widget _buildPlaylistCardWithOverlay(
      Map<String, dynamic> playlist, double size) {
    // Use the image provided in the playlist map, which should be randomized by the caller.
    String? imageUrl = playlist['image'] as String?;

    // Fallback to a random image if the caller didn't provide one.
    if ((imageUrl == null || imageUrl.isEmpty) &&
        playlist['list'] != null &&
        (playlist['list'] as List).isNotEmpty) {
      imageUrl = _getRandomPlaylistImage(playlist['list']);
    }

    // Final fallback to a default asset.
    imageUrl ??= 'assets/images/JTunes.png';
    // Remove playlist title overlay from the card image
    return Container(
      height: size * 0.75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Colors.grey.withOpacity(0.3),
          width: 1.0,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            imageUrl.startsWith('http')
                ? Transform.scale(
                    scale: 1.4, // Increased value to crop/zoom more
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200], // Subtle gray background
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  )
                : Transform.scale(
                    scale: 1.4, // Increased value to crop/zoom more
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey[200], // Subtle gray background
                        child: Center(
                          child: Icon(
                            Icons.music_note,
                            color: Theme.of(context).colorScheme.primary,
                            size: 30,
                          ),
                        ),
                      ),
                    ),
                  ),
            // Playlist text at top right
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'Playlist',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 2,
                        color: Colors.black87,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Playlist name at bottom is removed
          ],
        ),
      ),
    );
  }

  // NEW METHOD - First 4 songs ka combined image banane ke liye

  // Helper method for individual grid images
}

class _HomeRecentsSectionShimmer extends StatelessWidget {
  const _HomeRecentsSectionShimmer();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
          child: ShimmerBox(
            height: 22,
            width: MediaQuery.of(context).size.width * 0.4,
            borderRadius: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 52,
            ),
            itemBuilder: (context, index) => const ShimmerBox(
                height: 52,
                width: double.infinity,
                borderRadius: 4,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _buildImageWidget(String imageUrl) {
  return imageUrl.startsWith('http')
      ? Image.network(imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.music_note))
      : Image.asset(imageUrl, fit: BoxFit.cover);
}

Widget _buildTitleWidget(String title) {
  return Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: Text(title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
    ),
  );
}
