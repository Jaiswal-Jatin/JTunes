import 'package:j3tunes/services/youtube_service.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/playlist_page.dart';
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
  Future<dynamic>? _topSongsFuture;
  Future<dynamic>? _trendingSongsFuture;
  Future<dynamic>? _popSongsFuture;
  Future<dynamic>? _rockSongsFuture;
  Future<dynamic>? _bollywoodSongsFuture;
  Future<dynamic>? _punjabSongsFuture;
  Future<dynamic>? _marathiSongsFuture;
  Future<dynamic>? _teluguSongsFuture;
  Future<dynamic>? _tamilSongsFuture;
  Future<List<dynamic>>? _albumsFuture;

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
    Future.delayed(const Duration(milliseconds: 300), () async {
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
    Future.delayed(const Duration(milliseconds: 500), () async {
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

    // Top Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 800), () async {
      if (mounted) {
        final yt = YoutubeService();
        final topSongs = await yt.searchVideos('top songs', maxResults: 50);
        print('HomePage: fetched topSongs count: ${topSongs.length}');
        final filtered = topSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered top songs count: ${filtered.length}');

        setState(() {
          _topSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Trending songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 1200), () async {
      if (mounted) {
        final yt = YoutubeService();
        final trendingSongs =
            await yt.searchVideos('trending songs', maxResults: 50);
        print('HomePage: fetched trendingSongs count: ${trendingSongs.length}');
        final filtered = trendingSongs.where(isValidSong).take(12).toList();
        print('HomePage: filtered trending songs count: ${filtered.length}');

        setState(() {
          _trendingSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
        });
      }
    });

    // Pop Songs - Ensure minimum 10 songs
    Future.delayed(const Duration(milliseconds: 1600), () async {
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
    Future.delayed(const Duration(milliseconds: 2000), () async {
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
    Future.delayed(const Duration(milliseconds: 2400), () async {
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
    Future.delayed(const Duration(milliseconds: 2800), () async {
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
    Future.delayed(const Duration(milliseconds: 3200), () async {
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
    Future.delayed(const Duration(milliseconds: 3600), () async {
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
    Future.delayed(const Duration(milliseconds: 4000), () async {
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

    // Albums
    Future.delayed(const Duration(seconds: 5), () async {
      if (mounted) {
        final yt = YoutubeService();
        _albumsFuture = yt
            .searchPlaylists('album playlist',
                maxResults: recommendedCubesNumber * 2)
            .then((albums) async {
          print('HomePage: fetched albums playlists count: ${albums.length}');
          if (albums.isNotEmpty) {
            return albums.take(recommendedCubesNumber).map((p) {
              String image = p.thumbnails.highResUrl.isNotEmpty
                  ? p.thumbnails.highResUrl
                  : p.thumbnails.standardResUrl.isNotEmpty
                      ? p.thumbnails.standardResUrl
                      : p.thumbnails.mediumResUrl.isNotEmpty
                          ? p.thumbnails.mediumResUrl
                          : p.thumbnails.lowResUrl;

              if (image.isEmpty) {
                image = 'assets/images/JTunes.png';
              }

              return {
                'ytid': p.id,
                'title': p.title,
                'image': image,
                'playlist': p,
              };
            }).toList();
          } else {
            // Fallback: show top albums videos as "albums"
            final videos = await yt.searchVideos('top albums',
                maxResults: recommendedCubesNumber * 2);
            print('HomePage: fallback videos for albums: ${videos.length}');
            return videos
                .take(recommendedCubesNumber)
                .map((v) => videoToMap(v))
                .toList();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final playlistHeight = MediaQuery.sizeOf(context).height * 0.25 / 1.1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('JTunes'),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshContent,
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: 120, // Increased for mini player
            ),
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile - always show first
                const RepaintBoundary(
                  child: UserProfileCard(showGreeting: true),
                ),
                const SizedBox(height: 16),

                // 1. Suggested Playlists section (horizontal scroll)
                RepaintBoundary(
                  child: _buildSuggestedPlaylists(playlistHeight),
                ),

                // 2. Language Playlists section (horizontal scroll)
                if (_languagePlaylistsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildLanguagePlaylists(playlistHeight),
                  ),
                ],

                // 3. Top Songs section (horizontal scroll)
                if (_topSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🔥 Top Songs',
                      _topSongsFuture!,
                      'top_song',
                    ),
                  ),
                ],

                // 4. Trending Songs section (horizontal scroll)
                if (_trendingSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '📈 Trending Songs',
                      _trendingSongsFuture!,
                      'trending_song',
                    ),
                  ),
                ],

                // 5. Pop Songs section (horizontal scroll)
                if (_popSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎤 Pop Songs',
                      _popSongsFuture!,
                      'pop_song',
                    ),
                  ),
                ],

                // 6. Rock Songs section (horizontal scroll)
                if (_rockSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎸 Rock Songs',
                      _rockSongsFuture!,
                      'rock_song',
                    ),
                  ),
                ],

                // 7. Bollywood Songs section (horizontal scroll)
                if (_bollywoodSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎬 Bollywood Songs',
                      _bollywoodSongsFuture!,
                      'bollywood_song',
                    ),
                  ),
                ],

                // 8. Punjabi Songs section (horizontal scroll)
                if (_punjabSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎵 Punjabi Songs',
                      _punjabSongsFuture!,
                      'punjabi_song',
                    ),
                  ),
                ],

                // 9. Marathi Songs section (horizontal scroll)
                if (_marathiSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎶 Marathi Songs',
                      _marathiSongsFuture!,
                      'marathi_song',
                    ),
                  ),
                ],

                // 10. Telugu Songs section (horizontal scroll)
                if (_teluguSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎭 Telugu Songs',
                      _teluguSongsFuture!,
                      'telugu_song',
                    ),
                  ),
                ],

                // 11. Tamil Songs section (horizontal scroll)
                if (_tamilSongsFuture != null) ...[
                  RepaintBoundary(
                    child: _buildHorizontalSongsSection(
                      '🎨 Tamil Songs',
                      _tamilSongsFuture!,
                      'tamil_song',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshContent() async {
    setState(() {
      _suggestedPlaylistsFuture = null;
      _languagePlaylistsFuture = null;
      _likedPlaylistsFuture = null;
      _topSongsFuture = null;
      _trendingSongsFuture = null;
      _popSongsFuture = null;
      _rockSongsFuture = null;
      _bollywoodSongsFuture = null;
      _punjabSongsFuture = null;
      _marathiSongsFuture = null;
      _teluguSongsFuture = null;
      _tamilSongsFuture = null;
      _albumsFuture = null;
    });

    await Future.delayed(const Duration(milliseconds: 300));
    _initializeFutures();
  }

  Widget _buildLoadingWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(35),
        child: Spinner(),
      ),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    return Center(
      child: Text(
        '${context.l10n!.error}!',
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 18,
        ),
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
              SectionHeader(title: '🌍 Language Playlists', fontSize: 18),
              const SizedBox(height: 60, child: Center(child: Spinner())),
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
            SectionHeader(
              title: '🌍 Language Playlists',
              fontSize: 18,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: itemsNumber,
                itemBuilder: (context, index) {
                  final playlist = playlists[index] as Map<String, dynamic>;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
                      child: PlaylistCube(playlist, size: playlistHeight),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _buildHorizontalSongsSection(
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
              SectionHeader(title: title, fontSize: 18),
              const SizedBox(height: 60, child: Center(child: Spinner())),
              const SizedBox(height: 24),
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

        return Column(
          children: [
            SectionHeader(title: title, fontSize: 18),
            Container(
              height: 190, // Fixed height to prevent overflow
              margin: const EdgeInsets.only(bottom: 24),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: patchedData.length,
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
                    width: 150, // Slightly wider cards
                    margin: const EdgeInsets.only(right: 12),
                    child: RepaintBoundary(
                      key: ValueKey('${keyPrefix}_$ytid'),
                      child: _buildVerticalSongCard(songWithImage),
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

  Widget _buildVerticalSongCard(Map<String, dynamic> song) {
    return GestureDetector(
      onTap: () {
        // Play the song
        audioHandler.playSong(song);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Song Image - Bigger and at top
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Image.network(
                    song['lowResImage'] ?? song['image'] ?? '',
                    width: double.infinity,
                    height: 110, // Bigger image height
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 110,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.2),
                              Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withOpacity(0.1),
                            ],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            topRight: Radius.circular(16),
                          ),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 45,
                        ),
                      );
                    },
                  ),
                ),
                // Play Button Overlay
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
            // Song Details - Below image
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song['title'] ?? 'Unknown Title',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      song['artist'] ?? 'Unknown Artist',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestedPlaylists(
    double playlistHeight, {
    bool showOnlyLiked = false,
  }) {
    final sectionTitle = showOnlyLiked
        ? context.l10n!.backToFavorites
        : context.l10n!.suggestedPlaylists;
    final adjustedHeight =
        showOnlyLiked ? playlistHeight * 0.6 : playlistHeight;
    final future =
        showOnlyLiked ? _likedPlaylistsFuture : _suggestedPlaylistsFuture;

    if (future == null) {
      return showOnlyLiked ? const SizedBox.shrink() : _buildLoadingWidget();
    }

    return FutureBuilder<List<dynamic>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        } else if (snapshot.hasError) {
          logger.log(
            'Error in _buildSuggestedPlaylists',
            snapshot.error,
            snapshot.stackTrace,
          );
          return _buildErrorWidget(context);
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32.0),
            child: Center(
              child: Text(
                '',
                style: TextStyle(
                    fontSize: 16, color: Theme.of(context).colorScheme.primary),
                textAlign: TextAlign.center,
              ),
            ),
          );
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
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        if (playlists.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          children: [
            SectionHeader(
              title: sectionTitle,
              fontSize: 18,
            ),
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
            const SizedBox(height: 24),
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
        horizontal: showOnlyLiked ? 12 : 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        final playlist = playlists[index] as Map<String, dynamic>;
        // Debug print for playlist image
        print(
            '[HomePage] Playlist: ${playlist['title']} | image: ${playlist['image']}');
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: showOnlyLiked ? 4 : 8,
          ),
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
            child: PlaylistCube(playlist, size: height),
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
    if (showOnlyLiked) {
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          final playlist = playlists[index] as Map<String, dynamic>;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
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
              child: PlaylistCube(playlist, size: height),
            ),
          );
        },
      );
    }

    return CarouselView.weighted(
      flexWeights: const <int>[3, 2, 1],
      itemSnapping: true,
      onTap: (index) {
        final playlist = playlists[index] as Map<String, dynamic>;
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
      children: List.generate(itemCount, (index) {
        final playlist = playlists[index] as Map<String, dynamic>;
        // Debug print for playlist image (carousel)
        print(
            '[HomePage] Playlist (carousel): ${playlist['title']} | image: ${playlist['image']}');
        return PlaylistCube(playlist, size: height * 2);
      }),
    );
  }
}
