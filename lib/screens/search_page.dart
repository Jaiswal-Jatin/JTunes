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
import 'package:j3tunes/API/musify.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);

class _SearchPageState extends State<SearchPage> {
  // Helper to convert Video object to Map for UI widgets
  Map<String, dynamic> videoToMap(dynamic video) {
    // Defensive: support both Video and Map
    if (video is Map<String, dynamic>) return video;
    String? imageUrl;
    try {
      imageUrl = video.thumbnails?.highResUrl;
    } catch (_) {
      imageUrl = null;
    }
    return {
      'title': video.title ?? '',
      'ytid': video.id?.value ?? '',
      'image': imageUrl ?? 'assets/images/JTunes.png',
      'lowResImage': imageUrl ?? 'assets/images/JTunes.png',
      'artist': video.author ?? '',
      'duration': video.duration?.inSeconds ?? 0,
      'description': video.description ?? '',
    };
  }

  final TextEditingController searchController = TextEditingController();
  List<String> searchHistory = [];
  bool showResults = false;
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  int maxSongsInList = 10;
  Timer? _debounceTimer;
  List _songsSearchResult = [];
  List _albumsSearchResult = [];
  List _playlistsSearchResult = [];
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

  // Search history load karne ka function (ab sahi async/await ke sath)
  void loadSearchHistory() async {
    final history = await data_manager.getData('user', 'searchHistory');
    setState(() {
      searchHistory = List<String>.from((history as Iterable<dynamic>));
    });
  }

  void onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      // Add to history
      if (!searchHistory.contains(query)) {
        searchHistory.insert(0, query);
        if (searchHistory.length > 10) {
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

  // Enhanced performSearch function with better playlist handling
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
          _playlistsSearchResult.clear();
        });

        // Search for songs using the enhanced search function
        final songResults = await search(query, 'song');
        
        if (!mounted) return;
        setState(() {
          _songsSearchResult = songResults.take(20).toList();
        });

        // Search for playlists with proper song loading
        await _loadPlaylistsWithSongs(query);
        
      } catch (e) {
        main_app.logger.log('Search error: $e', null, null);
      } finally {
        if (!mounted) return;
        _fetchingSongs.value = false;
      }
    });

    // Hide suggestions after search
    if (!mounted) return;
    setState(() {
      _suggestionsList.clear();
    });
  }

  // Enhanced playlist loading with songs
  Future<void> _loadPlaylistsWithSongs(String query) async {
    try {
      // Search for playlists using the enhanced search function
      final playlistResults = await search(query, 'playlist');
      
      // Load songs for each playlist
      final playlistsWithSongs = <Map<String, dynamic>>[];
      
      for (final playlist in playlistResults.take(5)) {
        try {
          // Ensure playlist has proper image
          String? playlistImage = playlist['image'] ?? 
                                 playlist['highResImage'] ?? 
                                 playlist['lowResImage'];
          
          // Get playlist info with songs
          final playlistInfo = await getPlaylistInfoForWidget(playlist['ytid']);
          if (playlistInfo != null && playlistInfo['list'] != null) {
            final playlistWithImage = Map<String, dynamic>.from(playlistInfo);
            // Ensure image is preserved
            if (playlistImage != null) {
              playlistWithImage['image'] = playlistImage;
            }
            playlistsWithSongs.add(playlistWithImage);
          } else {
            // If we can't get songs, still add the playlist but mark it
            playlist['list'] = [];
            if (playlistImage != null) {
              playlist['image'] = playlistImage;
            }
            playlistsWithSongs.add(playlist);
          }
        } catch (e) {
          main_app.logger.log('Error loading playlist ${playlist['ytid']}: $e', null, null);
          // Add playlist without songs as fallback
          playlist['list'] = [];
          playlistsWithSongs.add(playlist);
        }
      }

      if (!mounted) return;
      setState(() {
        _playlistsSearchResult = playlistsWithSongs;
      });
      
    } catch (e) {
      main_app.logger.log('Error loading playlists: $e', null, null);
    }
  }

  // Spotify-style: fetch live suggestions (dummy for now)
  Future<void> fetchSuggestions(String query) async {
    final lower = query.toLowerCase();
    final dummySuggestions = [
      '$query songs',
      '$query playlist',
      '$query album',
      'Best of $query',
      'Top $query hits',
      'Remix $query',
      'Live $query',
    ].where((s) => s.toLowerCase().contains(lower)).toList();
    setState(() {
      _suggestionsList = dummySuggestions;
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
              if (!showResults ||
                  (_songsSearchResult.isEmpty && _albumsSearchResult.isEmpty))
                _buildEnhancedHistorySection(primaryColor),

              // Enhanced Search Results Section
              if (showResults)
                _buildEnhancedResultsSection(primaryColor),
            ],
          ),
        ),
      ),
    );
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
                _songsSearchResult.length > maxSongsInList
                    ? maxSongsInList
                    : _songsSearchResult.length,
                (index) {
                  final borderRadius = getItemBorderRadius(
                    index,
                    _songsSearchResult.length > maxSongsInList
                        ? maxSongsInList
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
                _albumsSearchResult.length > maxSongsInList
                    ? maxSongsInList
                    : _albumsSearchResult.length,
                (index) {
                  final playlist = _albumsSearchResult[index];
                  final borderRadius = getItemBorderRadius(
                    index,
                    _albumsSearchResult.length > maxSongsInList
                        ? maxSongsInList
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
                _playlistsSearchResult.length > maxSongsInList
                    ? maxSongsInList
                    : _playlistsSearchResult.length,
                (index) {
                  final playlist = _playlistsSearchResult[index];
                  return PlaylistBar(
                    key: ValueKey(playlist['ytid']),
                    playlist['title'],
                    playlistId: playlist['ytid'],
                    playlistData: playlist,
                    playlistArtwork: playlist['image'] ?? playlist['highResImage'] ?? playlist['lowResImage'],
                    cubeIcon: FluentIcons.apps_list_24_filled,
                    borderRadius: getItemBorderRadius(
                      index,
                      _playlistsSearchResult.length > maxSongsInList
                          ? maxSongsInList
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
        return ConfirmationDialog(
          confirmationMessage: 'Remove "$query" from search history?',
          submitMessage: context.l10n!.confirm,
          onCancel: () => Navigator.of(context).pop(false),
          onSubmit: () => Navigator.of(context).pop(true),
        );
      },
    );
  }
}
