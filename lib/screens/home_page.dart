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
  Future<List<dynamic>>? _likedPlaylistsFuture;
  Future<dynamic>? _recommendedSongsFuture;
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

    // Top/recent songs
    Future.delayed(const Duration(seconds: 1), () async {
      if (mounted) {
        final yt = YoutubeService();
        // Use a better query for single tracks
        final topSongs =
            await yt.searchVideos('latest pop songs', maxResults: 50);
        print('HomePage: fetched topSongs count: ${topSongs.length}');
        // Filter for single, real songs (2-7 min, not mashup/remix/compilation)
        final filtered = topSongs.where(isValidSong).take(15).toList();
        print('HomePage: filtered recommended songs count: ${filtered.length}');
        setState(() {
          _recommendedSongsFuture =
              Future.value(filtered.map((v) => videoToMap(v)).toList());
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
      ),
      body: RefreshIndicator(
        onRefresh: _refreshContent,
        child: SingleChildScrollView(
          padding: commonSingleChildScrollViewPadding,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User profile - always show first
              const RepaintBoundary(child: UserProfileCard(showGreeting: true)),
              const SizedBox(height: 8),

              // 1. Playlists section (horizontal scroll)
              RepaintBoundary(
                child: _buildSuggestedPlaylists(playlistHeight),
              ),

              // 2. Top/Recent Songs section (vertical list)
              if (_recommendedSongsFuture != null) ...[
                RepaintBoundary(
                  child: _buildRecommendedSongsSection(playlistHeight),
                ),
              ],

              // 3. Albums section (horizontal scroll)
              // if (_albumsFuture != null) ...[
              //   RepaintBoundary(
              //     child: _buildAlbumsSection(playlistHeight),
              //   ),
              // ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshContent() async {
    setState(() {
      _suggestedPlaylistsFuture = null;
      _likedPlaylistsFuture = null;
      _recommendedSongsFuture = null;
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

  Widget _buildRecommendedSongsSection(double playlistHeight) {
    return ValueListenableBuilder<bool>(
      valueListenable: defaultRecommendations,
      builder: (_, recommendations, __) {
        return FutureBuilder<dynamic>(
          future: _recommendedSongsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingWidget();
            }

            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox.shrink();
            }

            if (snapshot.hasError) {
              logger.log(
                'Error in _buildRecommendedSongsSection',
                snapshot.error,
                snapshot.stackTrace,
              );
              return _buildErrorWidget(context);
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

            return _buildRecommendedForYouSection(context, patchedData);
          },
        );
      },
    );
  }

  Widget _buildRecommendedForYouSection(
    BuildContext context,
    List<dynamic> data,
  ) {
    return Column(
      children: [
        SectionHeader(
          title: context.l10n!.recommendedForYou,
          fontSize: 18,
        ),
        Column(
          children: List.generate(data.length, (index) {
            final item = data[index] as Map<String, dynamic>;
            final ytid = item['ytid'];
            final borderRadius = getItemBorderRadius(index, data.length);
            // Ensure image extraction is robust and log for debugging
            final songWithImage = Map<String, dynamic>.from(item);
            String? img = songWithImage['artUri'] ??
                songWithImage['image'] ??
                songWithImage['highResImage'];
            if (img == null || img.isEmpty) img = 'assets/images/JTunes.png';
            songWithImage['lowResImage'] = img;
            // Debug print to verify what image is being passed
            print(
                '[HomePage] Recommended Song: \'${songWithImage['title']}\' | ytid: $ytid | image: $img');
            return RepaintBoundary(
              key: ValueKey('song_$ytid'),
              child: SongBar(songWithImage, true, borderRadius: borderRadius),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildAlbumsSection(double playlistHeight) {
    return FutureBuilder<List<dynamic>>(
      future: _albumsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingWidget();
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final albums = snapshot.data ?? [];
        final itemsNumber = albums.length.clamp(0, recommendedCubesNumber);
        final isLargeScreen = MediaQuery.of(context).size.width > 480;

        return Column(
          children: [
            SectionHeader(
              title: context.l10n!.albums,
              fontSize: 18,
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: playlistHeight),
              child: isLargeScreen
                  ? _buildHorizontalList(
                      albums,
                      itemsNumber,
                      playlistHeight,
                    )
                  : _buildCarouselView(
                      albums,
                      itemsNumber,
                      playlistHeight,
                    ),
            ),
          ],
        );
      },
    );
  }
}
