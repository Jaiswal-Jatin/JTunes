// ignore_for_file: deprecated_member_use, omit_local_variable_types, unnecessary_lambdas, unawaited_futures, unused_field, unused_import, directives_ordering, require_trailing_commas, prefer_final_in_for_each, unused_element_parameter

import 'package:j3tunes/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/playlist_page.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/playlist_cube.dart';
import 'package:j3tunes/widgets/section_header.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/spinner.dart';
import 'package:j3tunes/widgets/user_profile_card.dart';
import 'package:j3tunes/widgets/shimmer_widgets.dart';
import 'dart:ui';

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
  // Keep the page alive to avoid rebuilding
  @override
  bool get wantKeepAlive => true;

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
  Future<dynamic>? _internationalSongsFuture;

  @override
  void initState() {
    super.initState();
    _initializeFutures();
  }

  void _initializeFutures() {
    // Always use the provided playlist IDs for home screen
    final yt = YoutubeService();
    const playlistIds = [
      'https://www.youtube.com/playlist?list=RDCLAK5uy_n9Fbdw7e6ap-98_A-8JYBmPv64v-Uaq1g&playnext=1&index=1',
      'https://www.youtube.com/playlist?list=RDCLAK5uy_kuo_NioExeUmw07dFf8BzQ64DFFTlgE7Q&playnext=1&index=1',
      'https://www.youtube.com/playlist?list=RDCLAK5uy_lj-zBExVYl7YN_NxXboDIh4A-wKGfgzNY&playnext=1&index=1',
      'PL4fGSI1pDJn5RgLW0Sb_zECecWdH_4zOX',
      'RDCLAK5uy_ksEjgm3H_7zOJ_RHzRjN1wY-_FFcs7aAU',
      'RDCLAK5uy_nlKphX00YtBNjlGZcmPifGNAPXUSjezNM',
      'RDCLAK5uy_lBa7h-v-su4TAsDNvyelrswt9YYYU7x4g',
      'PL4fGSI1pDJn40WjZ6utkIuj2rNg-7iGsq',
      'RDCLAK5uy_l_Bj8rMsjkhFMMs-eLrA17_zjr9r6g_Eg',
      'RDCLAK5uy_m_cn307EUnwiDOgAsOMM27CHhuJCX2ygk',
      'RDCLAK5uy_lbfDqlFOiRJekoTwNgiES65gcham4ZelA',
      'RDCLAK5uy_nGC5IUV3lYF-P_wGb-LzMPFydA-RkPblc',
      'RDCLAK5uy_kymAL5cE4HeekmTy6-3OXYuAucHRpvJ28',
    ];

    _suggestedPlaylistsFuture = Future.wait(playlistIds.map((id) async {
      List<Map<String, dynamic>> songMaps = [];
      String title = id;
      String image = 'assets/images/JTunes.png';

      try {
        songMaps = await yt.fetchPlaylistWithFallback(id);
        if (songMaps.isNotEmpty) {
          title = songMaps.first['title'] ?? id;
          image = songMaps.first['image'] ?? 'assets/images/JTunes.png';
        }
      } catch (e) {
        print('Error fetching playlist $id: $e');
      }

      return {
        'ytid': id,
        'title': title,
        'image': image,
        'list': songMaps,
      };
    })).then((list) => list);

    // Initialize other futures with reduced delays for better UX
    _initializeOtherFutures();
  }

  void _initializeOtherFutures() {
    // Liked playlists from local
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (mounted) {
        try {
          final likedIds = await getLikedPlaylists();
          final yt = YoutubeService();
          final likedPlaylists = <Map<String, dynamic>>[];

          for (final id in likedIds) {
            try {
              final songMaps = await yt.fetchPlaylistWithFallback(id);
              final safeSongMaps = safeListConvert(songMaps);
              if (safeSongMaps.isNotEmpty) {
                String image =
                    safeSongMaps.first['image'] ?? 'assets/images/JTunes.png';
                likedPlaylists.add({
                  'ytid': id,
                  'title': safeSongMaps.first['title'] ?? 'Liked Playlist',
                  'image': image,
                  'list': safeSongMaps,
                });
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

    // Initialize song futures with staggered delays
    _initializeSongFutures();
  }

  void _initializeSongFutures() {
    final songCategories = [
      {'name': 'trending songs 2025', 'delay': 400, 'future': 'trending'},
      {
        'name': 'kpop songs 2025 BTS Blackpink NewJeans',
        'delay': 600,
        'future': 'kpop'
      },
      {
        'name': 'international top songs 2025 english hits',
        'delay': 800,
        'future': 'international'
      },
      {'name': 'pop songs 2025', 'delay': 1000, 'future': 'pop'},
      {'name': 'rock songs 2025', 'delay': 1200, 'future': 'rock'},
      {'name': 'bollywood songs 2025', 'delay': 1400, 'future': 'bollywood'},
      {'name': 'punjabi songs 2025', 'delay': 1600, 'future': 'punjab'},
      {'name': 'marathi songs 2025', 'delay': 1800, 'future': 'marathi'},
      {'name': 'telugu songs 2025', 'delay': 2000, 'future': 'telugu'},
      {'name': 'tamil songs 2025', 'delay': 2200, 'future': 'tamil'},
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
        _trendingSongsFuture == null ||
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
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const HomeHeaderShimmer(),
                      HomePlaylistSectionShimmer(title: 'Suggested Playlists'),
                      HomeSongSectionShimmer(title: 'Trending'),
                      HomeSongSectionShimmer(title: 'Bollywood'),
                      HomeSongSectionShimmer(title: 'Punjabi'),
                      HomeSongSectionShimmer(title: 'Marathi'),
                      HomeSongSectionShimmer(title: 'Telugu'),
                      HomeSongSectionShimmer(title: 'Tamil'),
                      HomeSongSectionShimmer(title: 'K-Pop hits'),
                      HomeSongSectionShimmer(title: 'Pop music'),
                      HomeSongSectionShimmer(title: 'Rock'),
                      HomePlaylistSectionShimmer(title: 'Your Liked Playlists'),
                      const SizedBox(height: 80),
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

                      // Song sections with reduced spacing
                      ..._buildSongSections(),

                      // Liked Playlists at bottom with SAME UI as suggested playlists
                      if (_likedPlaylistsFuture != null) ...[
                        RepaintBoundary(
                          child: _buildLikedPlaylists(playlistHeight),
                        ),
                      ],

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
                  'Recently played',
                  Icons.history,
                  () {
                    NavigationManager.router.push('/library/userSongs/recents');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildQuickAccessButton(
                  'Suggested playlists',
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
                                'title': 'Suggested playlists',
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
              child: isLargeScreen
                  ? _buildHorizontalList(
                      playlists,
                      itemsNumber,
                      adjustedHeight,
                      showOnlyLiked: showOnlyLiked,
                    )
                  : _buildCarouselView(
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

        // Get first song's image from playlist for favorites
        String? dynamicPlaylistImage = playlist['image'];
        if (playlist['list'] != null && playlist['list'].isNotEmpty) {
          final firstSong = playlist['list'][0];
          dynamicPlaylistImage = firstSong['artUri'] ??
              firstSong['image'] ??
              firstSong['highResImage'] ??
              playlist['image'];
        }

        // Create modified playlist with dynamic image
        final modifiedPlaylist = Map<String, dynamic>.from(playlist);
        modifiedPlaylist['image'] = dynamicPlaylistImage;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showOnlyLiked ? 3 : 6, // Reduced spacing for liked
          ),
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
    // For favorites section, use regular ListView instead of CarouselView
    if (showOnlyLiked) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 10), // Reduced padding
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final playlist = playlists[index];
          String? dynamicPlaylistImage = playlist['image'];

          if (playlist['list'] != null && playlist['list'].isNotEmpty) {
            final firstSong = playlist['list'][0];
            dynamicPlaylistImage = firstSong['artUri'] ??
                firstSong['image'] ??
                firstSong['highResImage'] ??
                playlist['image'];
          }

          final modifiedPlaylist = Map<String, dynamic>.from(playlist);
          modifiedPlaylist['image'] = dynamicPlaylistImage;

          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 4), // Reduced spacing
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PlaylistPage(
                    playlistId: playlist['ytid'],
                    playlistData: playlist, // Pass data for liked playlists
                  ),
                ),
              ),
              child: _buildPlaylistCardWithOverlay(modifiedPlaylist, height),
            ),
          );
        },
      );
    }

    // Default CarouselView for suggested playlists
    return CarouselView.weighted(
      flexWeights: const <int>[3, 2, 1],
      itemSnapping: true,
      onTap: (index) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              PlaylistPage(playlistId: playlists[index]['ytid']),
        ),
      ),
      children: List.generate(itemCount, (index) {
        final playlist = playlists[index];
        String? dynamicPlaylistImage = playlist['image'];

        if (playlist['list'] != null && playlist['list'].isNotEmpty) {
          final firstSong = playlist['list'][0];
          dynamicPlaylistImage = firstSong['artUri'] ??
              firstSong['image'] ??
              firstSong['highResImage'] ??
              playlist['image'];
        }

        final modifiedPlaylist = Map<String, dynamic>.from(playlist);
        modifiedPlaylist['image'] = dynamicPlaylistImage;

        return _buildPlaylistCardWithOverlay(modifiedPlaylist, height * 2);
      }),
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
              child: isLargeScreen
                  ? _buildHorizontalList(
                      playlists,
                      itemsNumber,
                      playlistHeight,
                      showOnlyLiked: true, // This flag differentiates it
                    )
                  : _buildCarouselView(
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
        'title': 'Trending',
        'future': _trendingSongsFuture,
        'key': 'trending_song'
      },
      {
        'title': 'Bollywood',
        'future': _bollywoodSongsFuture,
        'key': 'bollywood_song'
      },
      {'title': 'Punjabi', 'future': _punjabSongsFuture, 'key': 'punjabi_song'},
      {
        'title': 'Marathi',
        'future': _marathiSongsFuture,
        'key': 'marathi_song'
      },
      {'title': 'Telugu', 'future': _teluguSongsFuture, 'key': 'telugu_song'},
      {'title': 'Tamil', 'future': _tamilSongsFuture, 'key': 'tamil_song'},
      {'title': 'K-Pop hits', 'future': _kpopSongsFuture, 'key': 'kpop_song'},
      {'title': 'Pop music', 'future': _popSongsFuture, 'key': 'pop_song'},
      {'title': 'Rock', 'future': _rockSongsFuture, 'key': 'rock_song'},
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
                      key: ValueKey('${keyPrefix}_$ytid}'),
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
        width: 110,
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

  // UPDATED PLAYLIST CARD METHOD - Ab first 4 songs ka combined image dikhega
  Widget _buildPlaylistCardWithOverlay(
      Map<String, dynamic> playlist, double size) {
    return Container(
      width: size,
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
            // Minimal Blurred Combined 4 Songs Image Grid Background
            _buildCombinedPlaylistImage(playlist),

            // Dark Overlay for better contrast
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
              ),
            ),

            // Playlist Text in Top Right
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
          ],
        ),
      ),
    );
  }

  // NEW METHOD - First 4 songs ka combined image banane ke liye
  Widget _buildCombinedPlaylistImage(Map<String, dynamic> playlist) {
    final List<dynamic> songs = playlist['list'] ?? [];
    final List<String> imageUrls = [];

    // First 4 songs ke images collect karo
    for (int i = 0; i < 4; i++) {
      if (i < songs.length) {
        final song = songs[i];
        String? imageUrl = song['artUri'] ??
            song['image'] ??
            song['highResImage'] ??
            song['lowResImage'];
        if (imageUrl != null &&
            imageUrl.isNotEmpty &&
            imageUrl != 'assets/images/JTunes.png') {
          imageUrls.add(imageUrl);
        } else {
          imageUrls.add('assets/images/JTunes.png'); // fallback
        }
      } else {
        imageUrls.add('assets/images/JTunes.png'); // fallback for missing songs
      }
    }

    // Agar koi images nahi mili to single default image show karo
    if (imageUrls.every((url) => url == 'assets/images/JTunes.png')) {
      return Container(
        color: Theme.of(context).colorScheme.surface,
        child: Icon(
          Icons.music_note,
          color: Theme.of(context).colorScheme.primary,
          size: 30,
        ),
      );
    }

    // 2x2 Grid banao
    return Row(
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              // Top-left image
              Expanded(
                child: _buildGridImage(imageUrls[0], isTopLeft: true),
              ),
              // Bottom-left image
              Expanded(
                child: _buildGridImage(imageUrls[2], isBottomLeft: true),
              ),
            ],
          ),
        ),
        // Right column
        Expanded(
          child: Column(
            children: [
              // Top-right image
              Expanded(
                child: _buildGridImage(imageUrls[1], isTopRight: true),
              ),
              // Bottom-right image
              Expanded(
                child: _buildGridImage(imageUrls[3], isBottomRight: true),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Helper method for individual grid images
  Widget _buildGridImage(
    String imageUrl, {
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Container(
      margin: EdgeInsets.only(
        right: isTopLeft || isBottomLeft ? 0.5 : 0,
        left: isTopRight || isBottomRight ? 0.5 : 0,
        bottom: isTopLeft || isTopRight ? 0.5 : 0,
        top: isBottomLeft || isBottomRight ? 0.5 : 0,
      ),
      child: imageUrl == 'assets/images/JTunes.png'
          ? Container(
              color: Theme.of(context).colorScheme.surface,
              child: Icon(
                Icons.music_note,
                color: Theme.of(context).colorScheme.primary,
                size: 16,
              ),
            )
          : Image.network(
              imageUrl,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Theme.of(context).colorScheme.surface,
                  child: Icon(
                    Icons.music_note,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                );
              },
            ),
    );
  }
}
