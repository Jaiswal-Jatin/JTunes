// ignore_for_file: unused_field, unnecessary_parenthesis, require_trailing_commas, prefer_const_constructors, prefer_int_literals, directives_ordering, prefer_final_fields, omit_local_variable_types, prefer_final_locals, avoid_redundant_argument_values

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
import 'package:j3tunes/widgets/confirmation_dialog.dart';
import 'package:j3tunes/widgets/custom_bar.dart';
import 'package:j3tunes/widgets/custom_search_bar.dart';
import 'package:j3tunes/widgets/playlist_bar.dart';
import 'package:j3tunes/widgets/section_title.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/API/musify.dart' as musify;
import 'package:j3tunes/screens/artist_page.dart';
import 'package:j3tunes/widgets/shimmer_widgets.dart';

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

        // Use the reliable search from musify.dart
        final songs = await musify.search(query, 'song');
        final playlists = await musify.search(query, 'playlist');
        // A simple way to get albums is to search for "query album"
        final albums = await musify.search('$query album', 'playlist');

        if (!mounted) return;
        setState(() {
          _songsSearchResult = songs;
          _playlistsSearchResult = playlists;
          _albumsSearchResult = albums;
          _artistsSearchResult = []; // Artist search is not supported by this method
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

              // Enhanced Trending Searches Section
              if (!showResults && searchController.text.isEmpty)
                _buildEnhancedTrendingSection(primaryColor),

              // Enhanced Live Suggestions Section
              if (_suggestionsList.isNotEmpty && searchController.text.isNotEmpty)
                _buildEnhancedSuggestionsSection(primaryColor),

              // Enhanced Search History Section
              if (!showResults && searchController.text.isEmpty)
                _buildEnhancedHistorySection(primaryColor),

              // Enhanced Search Results Section
              if (showResults) _buildSearchResults(primaryColor),
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

  Widget _buildEnhancedTrendingSection(Color primaryColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
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
                  child: const Icon(
                    Icons.trending_up,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trending Searches',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _trendingSearches.map((trend) {
              return GestureDetector(
                onTap: () {
                  searchController.text = trend;
                  onSearchSubmitted(trend);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.1),
                        primaryColor.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primaryColor.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    trend,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
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
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        children: [
          // Enhanced History Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        FluentIcons.history_24_regular,
                        color: primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Search History',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: clearSearchHistory,
                    icon: const Icon(
                      FluentIcons.delete_24_regular,
                      color: Colors.red,
                      size: 20,
                    ),
                    tooltip: 'Clear History',
                  ),
                ),
              ],
            ),
          ),

          // Enhanced History List
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
              itemCount: searchHistory.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              ),
              itemBuilder: (BuildContext context, int index) {
                final query = searchHistory[index];
                return ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      FluentIcons.history_24_regular,
                      color: primaryColor,
                      size: 16,
                    ),
                  ),
                  title: Text(
                    query,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert,
                      color: primaryColor.withOpacity(0.6),
                    ),
                    onSelected: (value) async {
                      if (value == 'remove') {
                        final confirm = await _showConfirmationDialog(context, query) ?? false;
                        if (confirm) {
                          setState(() {
                            searchHistory.remove(query);
                          });
                          await data_manager.addOrUpdateData('user', 'searchHistory', searchHistory);
                        }
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'remove',
                        child: Row(
                          children: [
                            const Icon(Icons.delete, color: Colors.red, size: 16),
                            const SizedBox(width: 8),
                            const Text('Remove'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    searchController.text = query;
                    await performSearch(query);
                    setState(() {
                      showResults = true;
                    });
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
              children: List.generate(
                _songsSearchResult.length > maxResultsToShow
                    ? maxResultsToShow
                    : _songsSearchResult.length,
                (index) {
                  final borderRadius = getItemBorderRadius(
                    index,
                    _songsSearchResult.length > maxResultsToShow
                        ? maxResultsToShow
                        : _songsSearchResult.length,
                  );
                  final song = _songsSearchResult[index];
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
                },
              ),
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
          _buildEnhancedSectionTitle('Albums', FluentIcons.cd_16_filled, primaryColor),
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
                _albumsSearchResult.length > maxResultsToShow
                    ? maxResultsToShow
                    : _albumsSearchResult.length,
                (index) {
                  final playlist = _albumsSearchResult[index];
                  final borderRadius = getItemBorderRadius(
                    index,
                    _albumsSearchResult.length > maxResultsToShow
                        ? maxResultsToShow
                        : _albumsSearchResult.length,
                  );
                  return PlaylistBar(
                    key: ValueKey(playlist['ytid']),
                    playlist['title'],
                    playlistId: playlist['ytid'],
                    playlistData: playlist,
                    playlistArtwork: playlist['image'],
                    cubeIcon: FluentIcons.cd_16_filled,
                    isAlbum: true,
                    borderRadius: borderRadius,
                  );
                },
              ),
            ),
          ),
        ],

        // Enhanced Playlists Section
        if (_playlistsSearchResult.isNotEmpty) ...[
          _buildEnhancedSectionTitle('Playlists', FluentIcons.apps_list_24_filled, primaryColor),
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
                _playlistsSearchResult.length > maxResultsToShow
                    ? maxResultsToShow
                    : _playlistsSearchResult.length,
                (index) {
                  final playlist = _playlistsSearchResult[index];
                  return PlaylistBar(
                    key: ValueKey(playlist['ytid']),
                    playlist['title'] ?? 'Unknown Playlist',
                    playlistId: playlist['ytid'],
                    playlistData: playlist,
                    playlistArtwork: playlist['thumbnails']?.last?['url'] ?? playlist['image'],
                    cubeIcon: FluentIcons.apps_list_24_filled,
                    borderRadius: getItemBorderRadius(
                      index,
                      _playlistsSearchResult.length > maxResultsToShow
                          ? maxResultsToShow
                          : _playlistsSearchResult.length,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
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
    return Column(
      children: const [
        HomeSongSectionShimmer(title: 'Songs'),
        HomeSongSectionShimmer(title: 'Artists'),
        HomePlaylistSectionShimmer(title: 'Playlists'),
      ],
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
