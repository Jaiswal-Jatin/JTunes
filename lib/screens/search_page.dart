// ignore_for_file: unused_field, unnecessary_parenthesis, require_trailing_commas, prefer_const_constructors, prefer_int_literals, directives_ordering, prefer_final_fields, omit_local_variable_types, prefer_final_locals, avoid_redundant_argument_values

import 'package:j3tunes/screens/playlist_page.dart';


import 'dart:async';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart' as main_app;
import 'package:j3tunes/services/data_manager.dart' as data_manager;
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/banner_ad_widget.dart';
import 'package:j3tunes/widgets/confirmation_dialog.dart';
import 'package:j3tunes/widgets/custom_bar.dart';
import 'package:j3tunes/widgets/custom_search_bar.dart';
import 'package:j3tunes/widgets/playlist_bar.dart';
import 'package:j3tunes/widgets/section_title.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/playlist_cube.dart';
import 'package:j3tunes/API/musify.dart' as musify;
import 'package:j3tunes/screens/artist_page.dart';
import 'package:j3tunes/widgets/shimmer_widgets.dart';
import 'package:shimmer/shimmer.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  List<String> searchHistory = [];
  bool showResults = false;
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  int maxResultsToShow = 5;
  Timer? _debounceTimer;

  // Separate lists for each category
  List _songsSearchResult = [];
  List _albumsSearchResult = [];
  List _playlistsSearchResult = [];
  List _artistsSearchResult = [];

  List<String> _suggestionsList = [];
  List<String> _trendingSearches = [
    'Arijit Singh',
    'Taylor Swift',
    'Top 100 Global Songs',
    'Top Bollywood Songs',
    'Bollywood Hits',
    'Top 50 Indian Songs',
    'Punjabi Hits',
    'Lo-fi',
    'Workout',
    'Romantic',
    'Party',
    'K-pop',
    'EDM',
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.clear();
    _inputNode.dispose();
    _fetchingSongs.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadSearchHistory();

    // Listen to text changes for live suggestions and clear results
    searchController.addListener(() {
      final text = searchController.text;
      if (text.isEmpty) {
        clearSearchResults();
        setState(() {
          _suggestionsList.clear();
        });
      } else {
        fetchSuggestions(text);
      }
    });
  }

  // Load search history from Hive
  Future<void> loadSearchHistory() async {
    final dynamic history = await data_manager.getData('user', 'searchHistory');
    if (mounted) {
      setState(() {
        searchHistory = (history is List) ? List<String>.from(history) : [];
      });
    }
  }

  void onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      // Add to history
      if (!searchHistory.contains(query)) {
        searchHistory.insert(0, query);
        if (searchHistory.length > 15) {
          searchHistory.removeLast();
        }
        data_manager.addOrUpdateData('user', 'searchHistory', searchHistory);
      }

      setState(() {
        showResults = true;
      });

      // Perform search
      performSearch(query);
    }
  }

  void clearSearchResults() {
    setState(() {
      _songsSearchResult.clear();
      _albumsSearchResult.clear();
      _playlistsSearchResult.clear();
      _artistsSearchResult.clear();
      _suggestionsList.clear();
      showResults = false;
    });
  }

  void clearSearchHistory() {
    setState(() {
      searchHistory.clear();
    });
    data_manager.addOrUpdateData('user', 'searchHistory', []);
    showToast(context, 'Search history cleared!');
  }

  Future<void> performSearch(String query) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty || query.length < 2) {
        clearSearchResults();
        return;
      }

      if (!mounted) return;
      _fetchingSongs.value = true;
      setState(() {
        _suggestionsList.clear();
      });

      try {
        if (!mounted) return;
        setState(() {
          _songsSearchResult.clear();
          _albumsSearchResult.clear();
          _artistsSearchResult.clear();
          _playlistsSearchResult.clear();
        });

        // Get initial songs for the query
        final songs = await musify.search(query, 'song');
        final List<Map<String, dynamic>> finalSongsList = List<Map<String, dynamic>>.from(songs);

        // If we found songs, get related songs for the top result
        if (songs.isNotEmpty) {
          final topSongId = songs.first['ytid'] as String?;
          if (topSongId != null) {
            final recommendedSongs = await musify.getNextRecommendedSongs(
              topSongId,
              count: 15, // Fetch more recommendations
              excludeIds: [topSongId],
            );

            // Add unique recommended songs to the list
            final seenIds = {topSongId};
            for (final recSong in recommendedSongs) {
              if (seenIds.add(recSong['ytid'] as String)) {
                finalSongsList.add(recSong);
              }
            }
          }
        }

        final playlists = await musify.search(query, 'playlist');
        final albums = await musify.search('$query album', 'playlist');
        final artists = await musify.search(query, 'artist');

        if (!mounted) return;
        setState(() {
          _songsSearchResult = finalSongsList;
          _playlistsSearchResult = playlists;
          _albumsSearchResult = albums;
          _artistsSearchResult = artists;
        });
        
      } catch (e) {
        main_app.logger.log('Search error: $e', null, null);
      } finally {
        if (mounted) {
          _fetchingSongs.value = false;
        }
      }
    });
  }

  // Fetch live suggestions from API
  Future<void> fetchSuggestions(String query) async {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () async {
      if (query.isNotEmpty) {
        final suggestions = await musify.getSearchSuggestions(query);
        if (mounted) {
          setState(() {
            _suggestionsList = suggestions;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final showSuggestions = _suggestionsList.isNotEmpty && searchController.text.isNotEmpty;
    final showInitialView = !showResults && !showSuggestions;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n!.search),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          clearSearchResults();
          loadSearchHistory();
        },
        color: primaryColor,
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: SingleChildScrollView(
          padding: commonSingleChildScrollViewPadding,
          child: Column(
            children: <Widget>[
              // Enhanced search bar
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: CustomSearchBar(
                  loadingProgressNotifier: _fetchingSongs,
                  controller: searchController,
                  focusNode: _inputNode,
                  labelText: '${context.l10n!.search}...',
                  onSubmitted: (String value) {
                    onSearchSubmitted(value);
                    _inputNode.unfocus();
                  },
                ),
              ),

              // Conditional UI
              if (showInitialView)
                _buildInitialSearchBody(primaryColor),
              if (showSuggestions)
                _buildEnhancedSuggestionsSection(primaryColor),
              if (showResults)
                _buildSearchResults(primaryColor),
              const RepaintBoundary(
                        child: BannerAdWidget(),
                      ), 
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(Color primaryColor) {
    if (_fetchingSongs.value) {
      return const SearchShimmer();
    }
    if (_songsSearchResult.isEmpty && _albumsSearchResult.isEmpty && _playlistsSearchResult.isEmpty && _artistsSearchResult.isEmpty) {
      return const NoResults();
    }
    return _buildEnhancedResultsSection(primaryColor);
  }

  Widget _buildInitialSearchBody(Color primaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (searchHistory.isNotEmpty) ...[
          _buildEnhancedHistorySection(primaryColor),
          const SizedBox(height: 24),
        ],
        _buildBrowseAllSection(primaryColor),
      ],
    );
  }

  Widget _buildBrowseAllSection(Color primaryColor) {
    final categories = [
      {'title': 'Top Hits', 'color': Colors.red, 'icon': FluentIcons.trophy_24_filled},
      {'title': 'Bollywood', 'color': Colors.orange, 'icon': FluentIcons.filmstrip_24_filled},
      {'title': 'Punjabi', 'color': Colors.green, 'icon': Icons.radio},
      {'title': 'K-Pop', 'color': Colors.pink, 'icon': FluentIcons.heart_24_filled},
      {'title': 'Romantic', 'color': Colors.redAccent, 'icon': FluentIcons.heart_pulse_24_filled},
      {'title': 'Party', 'color': Colors.purple, 'icon': FluentIcons.drink_margarita_24_filled},
      {'title': 'Workout', 'color': Colors.blue, 'icon': FluentIcons.dumbbell_24_filled},
      {'title': 'Lo-fi', 'color': Colors.teal, 'icon': FluentIcons.weather_moon_24_filled},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
          child: Text(
            'Browse Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: categories.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 16 / 8,
          ),
          itemBuilder: (context, index) {
            final category = categories[index];
            final title = category['title'] as String;
            final color = category['color'] as Color;
            final icon = category['icon'] as IconData;

            return GestureDetector(
              onTap: () {
                searchController.text = title;
                onSearchSubmitted(title);
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color.withOpacity(0.7), color],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -20,
                      right: -15,
                      child: Icon(
                        icon,
                        size: 80,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedSuggestionsSection(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Icon(
                  FluentIcons.lightbulb_24_regular,
                  color: primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Suggestions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _suggestionsList.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
              itemBuilder: (context, index) {
                final suggestion = _suggestionsList[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FluentIcons.search_24_regular,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    suggestion,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Icon(
                    Icons.north_west,
                    color: primaryColor.withOpacity(0.6),
                    size: 16,
                  ),
                  onTap: () {
                    searchController.text = suggestion;
                    onSearchSubmitted(suggestion);
                    _inputNode.unfocus();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedHistorySection(Color primaryColor) {
    if (searchHistory.isEmpty) return const SizedBox.shrink();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Searches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (searchHistory.isNotEmpty)
                TextButton(
                  onPressed: clearSearchHistory,
                  child: Text(
                    'CLEAR ALL',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: searchHistory.length > 5 ? 5 : searchHistory.length,
          itemBuilder: (BuildContext context, int index) {
            final query = searchHistory[index];
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              leading: Icon(FluentIcons.history_24_regular, color: Theme.of(context).colorScheme.secondary),
              title: Text(
                query,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              trailing: IconButton(
                icon: Icon(Icons.clear, size: 20, color: Theme.of(context).colorScheme.secondary.withOpacity(0.7)),
                tooltip: 'Remove from history',
                onPressed: () async {
                  final confirm = await _showConfirmationDialog(context, query) ?? false;
                  if (confirm) {
                    setState(() {
                      searchHistory.remove(query);
                    });
                    await data_manager.addOrUpdateData('user', 'searchHistory', searchHistory);
                  }
                },
              ),
              onTap: () {
                searchController.text = query;
                onSearchSubmitted(query);
                _inputNode.unfocus();
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildEnhancedResultsSection(Color primaryColor) {    
    return Column(
      children: [
        // Enhanced Songs Section
        if (_songsSearchResult.isNotEmpty) ...[
          _buildEnhancedSectionTitle('Songs', FluentIcons.music_note_1_24_regular, primaryColor),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: List.generate(() {
                final songCount = _songsSearchResult.length > maxResultsToShow ? maxResultsToShow : _songsSearchResult.length;
                final adCount = (songCount / 10).floor();
                return songCount + adCount;
              }(), (index) {
                const adInterval = 10;
                if (index > 0 && (index + 1) % (adInterval + 1) == 0) {
                  return const RepaintBoundary(child: BannerAdWidget());
                }
                final songIndex = index - (index ~/ (adInterval + 1));

                final songCount = _songsSearchResult.length > maxResultsToShow ? maxResultsToShow : _songsSearchResult.length;
                final borderRadius = getItemBorderRadius(
                  songIndex,
                  songCount,
                );
                final song = _songsSearchResult[songIndex];
                final songWithImage = song is Map<String, dynamic>
                    ? Map<String, dynamic>.from(song)
                    : song;
                if (songWithImage is Map<String, dynamic> &&
                    songWithImage['image'] != null) {
                  songWithImage['lowResImage'] = songWithImage['image'];
                  }
                  return SongBar(
                    songWithImage,
                    true,
                    showMusicDuration: false,
                    borderRadius: borderRadius,
                    backgroundColor: Colors.transparent,
                  );
              }),
            ),
          ),
        ],

        // Artists Section
        if (_artistsSearchResult.isNotEmpty) ...[
          _buildEnhancedSectionTitle('Artists', FluentIcons.person_24_regular, primaryColor),
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
            ),
            child: Column(
              children: List.generate(
                _artistsSearchResult.length > maxResultsToShow
                    ? maxResultsToShow
                    : _artistsSearchResult.length,
                (index) {
                  final artist = _artistsSearchResult[index];
                  return _buildArtistTile(
                    artist,
                    primaryColor,
                  );
                },
              ),
            ),
          ),
        ],

        // Enhanced Albums Section
        if (_albumsSearchResult.isNotEmpty) ...[
          _buildHorizontalCardSection(
            title: 'Albums',
            icon: FluentIcons.cd_16_filled,
            primaryColor: primaryColor,
            items: _albumsSearchResult,
            isAlbum: true,
          ),
        ],

        // Enhanced Playlists Section
        if (_playlistsSearchResult.isNotEmpty) ...[
          _buildHorizontalCardSection(
            title: 'Playlists',
            icon: FluentIcons.apps_list_24_filled,
            primaryColor: primaryColor,
            items: _playlistsSearchResult,
            isAlbum: false,
          ),
        ],
      ],
    );
  }

  Widget _buildHorizontalCardSection({
    required String title,
    required IconData icon,
    required Color primaryColor,
    required List items,
    required bool isAlbum,
  }) {
    const cardSize = 150.0;
    return Column(
      children: [
        _buildEnhancedSectionTitle(title, icon, primaryColor),
        SizedBox(
          height: cardSize + 50, // Card size + text height + padding
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PlaylistPage(playlistData: item),
                  ),
                ),
                child: Container(
                  width: cardSize,
                  margin: const EdgeInsets.only(right: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlaylistCube(item, size: cardSize, cubeIcon: icon),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] ?? 'Unknown',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistTile(Map artist, Color primaryColor) {
    final imageUrl = artist['thumbnails']?.last?['url'];
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (imageUrl != null) ? NetworkImage(imageUrl) : null,
        backgroundColor: primaryColor.withOpacity(0.1),
        child: (imageUrl == null)
            ? Icon(FluentIcons.person_24_filled, color: primaryColor)
            : null,
      ),
      title: Text(
        artist['artist'] ?? 'Unknown Artist',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Artist',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
        ),
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ArtistPage(artistName: artist['artist']),
          ),
        );
      },
    );
  }

  Widget _buildEnhancedSectionTitle(String title, IconData icon, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(BuildContext context, String query) {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Remove from History'),
          content: Text('Remove "$query" from your search history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('CANCEL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('REMOVE'),
            ),
          ],
        );
      },
    );
  }
}

class SearchShimmer extends StatelessWidget {
  const SearchShimmer({super.key});
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      highlightColor: Theme.of(context).colorScheme.surfaceVariant,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer for Songs section
            _buildShimmerSectionTitle(context),
            _buildShimmerList(context, 5),
            const SizedBox(height: 24),

            // Shimmer for Albums section
            _buildShimmerSectionTitle(context),
            _buildShimmerHorizontalList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerSectionTitle(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 4),
      child: _ShimmerBox(height: 24, width: 120, borderRadius: 8),
    );
  }

  Widget _buildShimmerList(BuildContext context, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: List.generate(count, (index) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            child: Row(
              children: [
                _ShimmerBox(height: 56, width: 56, borderRadius: 8),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(height: 16, width: double.infinity, borderRadius: 4),
                      SizedBox(height: 8),
                      _ShimmerBox(height: 12, width: 100, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class NoResults extends StatelessWidget {
  const NoResults({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              FluentIcons.search_info_24_regular,
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different keyword or check your spelling.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double height;
  final double width;
  final double borderRadius;

  const _ShimmerBox({
    required this.height,
    required this.width,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white, // This color will be overridden by Shimmer.fromColors
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

Widget _buildShimmerHorizontalList(BuildContext context) {
  const cardSize = 150.0;
  return SizedBox(
    height: cardSize + 50,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: 5,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemBuilder: (context, index) {
        return Container(
          width: cardSize,
          margin: const EdgeInsets.only(right: 16),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerBox(height: cardSize, width: cardSize, borderRadius: 12),
              SizedBox(height: 8),
              _ShimmerBox(height: 14, width: 120, borderRadius: 4),
            ],
          ),
        );
      },
    ),
  );
}
