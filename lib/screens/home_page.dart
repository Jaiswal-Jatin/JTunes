// ignore_for_file: deprecated_member_use, omit_local_variable_types, unnecessary_lambdas, unawaited_futures

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
  Future<List<dynamic>>? _languagePlaylistsFuture;
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
    // Initialize futures but don't await them to avoid blocking UI
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

    // Language-wise playlists
    Future.delayed(const Duration(milliseconds: 200), () async {
      if (mounted) {
        final yt = YoutubeService();
        final languagePlaylists = <Map<String, dynamic>>[];

        // Hindi/Bollywood Playlists
        const hindiPlaylistIds = [
          'PLrAl-OP1_0Dt5cLz4dEJsRdOb1Uz5YuL4', // Top 50 Indian Songs
          'PLFgquLnL59alCl_2TQvOiD5Vgm1hCaGSI', // Bollywood Hits 2024
          'PLQlnTldJs0FQBK_JAq_u9ROLYtaQyC4HS', // Hindi Romantic Songs
          'RDCLAK5uy_lj-zBExVYl7YN_NxXboDIh4A-wKGfgzNY', // Hindi Top Charts
        ];

        // Punjabi Playlists
        const punjabiPlaylistIds = [
          'PLw-VjHDlEOgvtOIqzx8FGO6p2pP6K6XMH', // Punjabi Top Hits
          'RDCLAK5uy_kymAL5cE4HeekmTy6-3OXYuAucHRpvJ28', // Punjabi Charts
        ];

        // Telugu Playlists
        const teluguPlaylistIds = [
          'PLQlnTldJs0FRrKRAM9sAURxqjC8jSWNHw', // Telugu Superhits
          'RDCLAK5uy_m_cn307EUnwiDOgAsOMM27CHhuJCX2ygk', // Telugu Top Songs
        ];

        // Tamil Playlists
        const tamilPlaylistIds = [
          'PLrAl-OP1_0DtNjO1YpFMXKL7Q6hBUy7DU', // Tamil Top Hits
          'RDCLAK5uy_lbfDqlFOiRJekoTwNgiES65gcham4ZelA', // Tamil Charts
        ];

        // Marathi Playlists (search-based since specific IDs might not be available)
        try {
          final marathiPlaylists =
              await yt.searchPlaylists('marathi songs playlist', maxResults: 2);
          for (final playlist in marathiPlaylists) {
            final songMaps =
                await yt.fetchPlaylistWithFallback(playlist.id.value);
            if (songMaps.isNotEmpty) {
              languagePlaylists.add({
                'ytid': playlist.id.value,
                'title': '🎵 ${playlist.title}',
                'image': playlist.thumbnails.highResUrl.isNotEmpty
                    ? playlist.thumbnails.highResUrl
                    : 'assets/images/JTunes.png',
                'list': songMaps,
                'language': 'Marathi',
              });
            }
          }
        } catch (e) {
          print('Error fetching Marathi playlists: $e');
        }

        // Process all language playlists
        final allLanguageIds = [
          ...hindiPlaylistIds,
          ...punjabiPlaylistIds,
          ...teluguPlaylistIds,
          ...tamilPlaylistIds,
        ];

        final languageLabels = {
          ...{for (var id in hindiPlaylistIds) id: '🇮🇳 Hindi'},
          ...{for (var id in punjabiPlaylistIds) id: '🎵 Punjabi'},
          ...{for (var id in teluguPlaylistIds) id: '🎬 Telugu'},
          ...{for (var id in tamilPlaylistIds) id: '🎭 Tamil'},
        };

        for (final id in allLanguageIds) {
          try {
            final songMaps = await yt.fetchPlaylistWithFallback(id);
            if (songMaps.isNotEmpty) {
              languagePlaylists.add({
                'ytid': id,
                'title': '${languageLabels[id]} Hits',
                'image': songMaps.first['image'] ?? 'assets/images/JTunes.png',
                'list': songMaps,
                'language': languageLabels[id]?.split(' ').last ?? 'Unknown',
              });
            }
          } catch (e) {
            print('Error fetching language playlist $id: $e');
          }
        }

        // Shuffle for variety
        languagePlaylists.shuffle();
        setState(() {
          _languagePlaylistsFuture = Future.value(languagePlaylists);
        });
      }
    });

    // Liked playlists from local
    Future.delayed(const Duration(milliseconds: 300), () async {
      if (mounted) {
        final likedIds = await getLikedPlaylists();
        final yt = YoutubeService();
        final likedPlaylists = <Map>[];

        for (final id in likedIds) {
          final songMaps = await yt.fetchPlaylistWithFallback(id);
          if (songMaps.isNotEmpty) {
            String image =
                songMaps.first['image'] ?? 'assets/images/JTunes.png';
            likedPlaylists.add({
              'ytid': id,
              'title': songMaps.first['title'] ?? '',
              'image': image,
              'list': songMaps,
            });
          }
        }

        setState(() {
          _likedPlaylistsFuture = Future.value(likedPlaylists);
        });
      }
    });

    // Trending songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 600), () async {
      if (mounted) {
        final yt = YoutubeService();
        final trendingSongs =
            await yt.searchVideos('trending songs 2025', maxResults: 50);
        print('HomePage: fetched trendingSongs count: ${trendingSongs.length}');
        final filtered = trendingSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered trending songs count: ${filtered.length}');
        setState(() {
          _trendingSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // K-Pop Songs - NEW CATEGORY
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        final yt = YoutubeService();
        final kpopSongs = await yt.searchVideos(
            'kpop songs 2025 BTS Blackpink NewJeans',
            maxResults: 50);
        print('HomePage: fetched kpopSongs count: ${kpopSongs.length}');
        final filtered = kpopSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered kpop songs count: ${filtered.length}');
        setState(() {
          _kpopSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // International Top Songs - NEW CATEGORY
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (mounted) {
        final yt = YoutubeService();
        final internationalSongs = await yt.searchVideos(
            'international top songs 2025 english hits',
            maxResults: 50);
        print(
            'HomePage: fetched internationalSongs count: ${internationalSongs.length}');
        final filtered =
            internationalSongs.where(isValidSong).take(12).toList();
        print(
            'HomePage: filtered international songs count: ${filtered.length}');
        setState(() {
          _internationalSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Pop Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (mounted) {
        final yt = YoutubeService();
        final popSongs =
            await yt.searchVideos('pop songs 2025', maxResults: 50);
        print('HomePage: fetched popSongs count: ${popSongs.length}');
        final filtered = popSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered pop songs count: ${filtered.length}');
        setState(() {
          _popSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Rock Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 1400), () async {
      if (mounted) {
        final yt = YoutubeService();
        final rockSongs =
            await yt.searchVideos('rock songs 2025', maxResults: 50);
        print('HomePage: fetched rockSongs count: ${rockSongs.length}');
        final filtered = rockSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered rock songs count: ${filtered.length}');
        setState(() {
          _rockSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Bollywood Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 1600), () async {
      if (mounted) {
        final yt = YoutubeService();
        final bollywoodSongs =
            await yt.searchVideos('bollywood songs 2025', maxResults: 50);
        print(
            'HomePage: fetched bollywoodSongs count: ${bollywoodSongs.length}');
        final filtered = bollywoodSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered bollywood songs count: ${filtered.length}');
        setState(() {
          _bollywoodSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Punjabi Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 1800), () async {
      if (mounted) {
        final yt = YoutubeService();
        final punjabSongs =
            await yt.searchVideos('punjabi songs 2025', maxResults: 50);
        print('HomePage: fetched punjabSongs count: ${punjabSongs.length}');
        final filtered = punjabSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered punjab songs count: ${filtered.length}');
        setState(() {
          _punjabSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Marathi Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 2000), () async {
      if (mounted) {
        final yt = YoutubeService();
        final marathiSongs =
            await yt.searchVideos('marathi songs 2025', maxResults: 50);
        print('HomePage: fetched marathiSongs count: ${marathiSongs.length}');
        final filtered = marathiSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered marathi songs count: ${filtered.length}');
        setState(() {
          _marathiSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Telugu Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 2200), () async {
      if (mounted) {
        final yt = YoutubeService();
        final teluguSongs =
            await yt.searchVideos('telugu songs 2025', maxResults: 50);
        print('HomePage: fetched teluguSongs count: ${teluguSongs.length}');
        final filtered = teluguSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered telugu songs count: ${filtered.length}');
        setState(() {
          _teluguSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Tamil Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 2400), () async {
      if (mounted) {
        final yt = YoutubeService();
        final tamilSongs =
            await yt.searchVideos('tamil songs 2025', maxResults: 50);
        print('HomePage: fetched tamilSongs count: ${tamilSongs.length}');
        final filtered = tamilSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered tamil songs count: ${filtered.length}');
        setState(() {
          _tamilSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });
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
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshContent,
          color: Theme.of(context).colorScheme.primary,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header like YouTube Music/Spotify
                _buildHeader(),

                // Playlist Section (old suggested playlists section)
                RepaintBoundary(
                  child: _buildSuggestedPlaylists(playlistHeight),
                ),

                // Trending
                if (_trendingSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Trending',
                      _trendingSongsFuture!,
                      'trending_song',
                    ),
                  ),
                ],

                // // International
                // if (_internationalSongsFuture != null) ...[
                //   RepaintBoundary(
                //     child: _buildHorizontalSongsSectionWithSeeAll(
                //       'International',
                //       _internationalSongsFuture!,
                //       'international_song',
                //     ),
                //   ),
                // ],

                // Bollywood
                if (_bollywoodSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Bollywood',
                      _bollywoodSongsFuture!,
                      'bollywood_song',
                    ),
                  ),
                ],

                // Punjabi
                if (_punjabSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Punjabi',
                      _punjabSongsFuture!,
                      'punjabi_song',
                    ),
                  ),
                ],

                // Marathi
                if (_marathiSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Marathi',
                      _marathiSongsFuture!,
                      'marathi_song',
                    ),
                  ),
                ],

                // Telugu
                if (_teluguSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Telugu',
                      _teluguSongsFuture!,
                      'telugu_song',
                    ),
                  ),
                ],

                // Tamil
                if (_tamilSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Tamil',
                      _tamilSongsFuture!,
                      'tamil_song',
                    ),
                  ),
                ],

                // K-Pop
                if (_kpopSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'K-Pop hits',
                      _kpopSongsFuture!,
                      'kpop_song',
                    ),
                  ),
                ],

                // Pop
                if (_popSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Pop music',
                      _popSongsFuture!,
                      'pop_song',
                    ),
                  ),
                ],

                // Rock
                if (_rockSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSectionWithSeeAll(
                      'Rock',
                      _rockSongsFuture!,
                      'rock_song',
                    ),
                  ),
                ],

                // Language Playlists at bottom
                if (_languagePlaylistsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildLanguagePlaylists(playlistHeight),
                  ),
                ],

                // Bottom padding for mini player
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting like Spotify
          Text(
            _getGreeting(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 20),

          // Quick access buttons like Spotify
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessButton(
                  'Liked Songs',
                  Icons.favorite,
                  () {
                    // Push Liked Songs as a new route so back returns to Home
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
          const SizedBox(height: 8),
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
                  'Made for you',
                  Icons.auto_awesome,
                  () async {
                    // Open a playlist page with 50 trending songs
                    if (_trendingSongsFuture != null) {
                      final snapshot = await _trendingSongsFuture;
                      if (snapshot is List && snapshot.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistPage(
                              playlistData: {
                                'title': 'Made for You',
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
        height: 56,
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
              width: 56,
              height: 56,
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
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
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

  Future<void> _refreshContent() async {
    setState(() {
      _suggestedPlaylistsFuture = null;
      _languagePlaylistsFuture = null;
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

  Widget _buildLanguagePlaylists(double playlistHeight) {
    if (_languagePlaylistsFuture == null) {
      return _buildLoadingWidget();
    }

    return FutureBuilder<List<dynamic>>(
      future: _languagePlaylistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Column(
            children: [
              _buildSectionHeader('More of what you like'),
              _buildLoadingWidget(),
            ],
          );
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildLanguagePlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return const SizedBox.shrink();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final playlists = snapshot.data ?? [];
        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);

        if (playlists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            _buildSectionHeader('More of what you like'),
            Container(
              height: playlistHeight,
              margin: const EdgeInsets.only(bottom: 32),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: itemsNumber,
                itemBuilder: (context, index) {
                  final playlist = playlists[index] as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistPage(
                              playlistId: playlist['ytid'],
                              playlistData: playlist,
                            ),
                          ),
                        );
                      },
                      child: _buildPlaylistCard(playlist, playlistHeight),
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

  Widget _buildSectionHeader(String title, {VoidCallback? onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          20, 16, 20, 4), // More top padding, minimal bottom
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
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
          return Column(
            children: [
              _buildSectionHeader(title, onSeeAll: null),
              _buildLoadingWidget(),
            ],
          );
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
        // Show at least 20, up to 30 songs if available
        final int minSongs = 20;
        final int maxSongs = 30;
        final int showCount = patchedData.length < minSongs
            ? patchedData.length
            : (patchedData.length > maxSongs ? maxSongs : patchedData.length);
        return Column(
          children: [
            _buildSectionHeader(title, onSeeAll: () {
              // See All: open PlaylistPage with all songs (20-30)
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
              height: 180,
              margin:
                  const EdgeInsets.only(bottom: 8), // Minimized bottom margin
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                    horizontal: 8), // Minimized horizontal padding
                itemCount: showCount,
                itemBuilder: (context, index) {
                  final item = patchedData[index] as Map<String, dynamic>;
                  final ytid = item['ytid'];
                  // Ensure image extraction is robust
                  final songWithImage = Map<String, dynamic>.from(item);
                  String? img = songWithImage['artUri'] ??
                      songWithImage['image'] ??
                      songWithImage['highResImage'];
                  if (img == null || img.isEmpty)
                    img = 'assets/images/JTunes.png';
                  songWithImage['lowResImage'] = img;
                  return Container(
                    width: 140,
                    margin: const EdgeInsets.only(
                        right: 6), // Minimized gap between cards
                    child: RepaintBoundary(
                      key: ValueKey('${keyPrefix}_$ytid'),
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
        // Play the song
        audioHandler.playSong(song);
      },
      child: SizedBox(
        width: 140,
        child: IntrinsicHeight(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 140,
                height: 140,
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
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 4), // Reduced top gap
              Flexible(
                child: Text(
                  song['title'] ?? 'Unknown Title',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 2), // Reduced bottom gap
              Flexible(
                child: Text(
                  song['artist'] ?? 'Unknown Artist',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    final sectionTitle =
        showOnlyLiked ? context.l10n!.backToFavorites : 'Made for you';
    final adjustedHeight =
        showOnlyLiked ? playlistHeight * 0.6 : playlistHeight;
    final future =
        showOnlyLiked ? _likedPlaylistsFuture : _suggestedPlaylistsFuture;

    if (future == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildSuggestedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return const SizedBox.shrink();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        // Only show playlists that have at least one song
        final allPlaylists = snapshot.data ?? [];
        final playlists = allPlaylists
            .where((p) =>
                (p is Map<String, dynamic>) &&
                (p['list'] is List) &&
                (p['list'] as List).isNotEmpty)
            .toList();

        final itemsNumber = playlists.length.clamp(0, recommendedCubesNumber);

        if (playlists.isEmpty) {
          return const SizedBox.shrink();
        }

        // Use old scroll effect: Always show scroll even if less items
        return Column(
          children: [
            _buildSectionHeader(sectionTitle),
            SizedBox(
              height: adjustedHeight,
              child: ClipRect(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: itemsNumber,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 6),
                  itemBuilder: (context, index) {
                    final playlist = playlists[index] as Map<String, dynamic>;
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PlaylistPage(
                              playlistId: playlist['ytid'],
                              playlistData: playlist,
                            ),
                          ),
                        );
                      },
                      child: _buildPlaylistCard(playlist, adjustedHeight),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaylistCard(Map<String, dynamic> playlist, double size) {
    return SizedBox(
      width: size,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: playlist['image'] != null &&
                      playlist['image'].toString().isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(playlist['image']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: (playlist['image'] == null || playlist['image'].isEmpty)
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: size,
            height: 36,
            child: Text(
              playlist['title'] ?? 'Unknown Playlist',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
