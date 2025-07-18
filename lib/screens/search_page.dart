// ignore_for_file: unused_field

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

import 'package:j3tunes/API/musify.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/confirmation_dialog.dart';
import 'package:j3tunes/widgets/custom_bar.dart';
import 'package:j3tunes/widgets/custom_search_bar.dart';
import 'package:j3tunes/widgets/playlist_bar.dart';
import 'package:j3tunes/widgets/section_title.dart';
import 'package:j3tunes/widgets/song_bar.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  _SearchPageState createState() => _SearchPageState();
}

List searchHistory = Hive.box('user').get('searchHistory', defaultValue: []);

class _SearchPageState extends State<SearchPage> {
  TextEditingController searchController = TextEditingController();
  List<String> searchHistory = [];
  bool showResults = false;
  final FocusNode _inputNode = FocusNode();
  final ValueNotifier<bool> _fetchingSongs = ValueNotifier(false);
  int maxSongsInList = 10;
  Timer? _debounceTimer;
  List _songsSearchResult = [];
  List _albumsSearchResult = [];
  List _playlistsSearchResult = [];
  // ignore: prefer_final_fields
  List _suggestionsList = [];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    searchController.dispose();
    _inputNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadSearchHistory();

    // Listen to text changes to clear results when empty
    searchController.addListener(() {
      if (searchController.text.isEmpty) {
        clearSearchResults();
      }
    });
  }

  void loadSearchHistory() async {
    final history = getData('user', 'searchHistory') ?? [];
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
        addOrUpdateData('user', 'searchHistory', searchHistory);
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
      showResults = false;
    });
  }

  void clearSearchHistory() {
    setState(() {
      searchHistory.clear();
    });
    addOrUpdateData('user', 'searchHistory', []);
    showToast(context, 'Search history cleared!');
  }

  // performSearch function ko replace karo
  Future<void> performSearch(String query) async {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      if (query.isEmpty || query.length < 2) {
        clearSearchResults();
        return;
      }

      setState(() {
        _fetchingSongs.value = true;
      });

      try {
        setState(() {
          _songsSearchResult.clear();
          _albumsSearchResult.clear();
          _playlistsSearchResult.clear();
        });

        final songResults = await fetchSongsList(query)
            .timeout(const Duration(seconds: 5))
            .catchError((e) {
          logger.log('Search error for songs: $e', null, null);
          return <Map>[];
        });

        setState(() {
          _songsSearchResult = songResults.take(20).toList();
        });

        _loadAlbumsAndPlaylists(query);
      } catch (e) {
        logger.log('Search error: $e', null, null);
      } finally {
        setState(() {
          _fetchingSongs.value = false;
        });
      }
    });
  }

  // Ye function add karo
  void _loadAlbumsAndPlaylists(String query) async {
    try {
      final albumResults = await getPlaylists(query: query, type: 'album')
          .timeout(const Duration(seconds: 3))
          .catchError((e) => <Map>[]);

      final playlistResults = await getPlaylists(query: query, type: 'playlist')
          .timeout(const Duration(seconds: 3))
          .catchError((e) => <Map>[]);

      setState(() {
        _albumsSearchResult = albumResults.take(10).toList();
        _playlistsSearchResult = playlistResults.take(10).toList();
      });
    } catch (e) {
      logger.log('Error loading albums/playlists: $e', null, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.search)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: <Widget>[
            CustomSearchBar(
              loadingProgressNotifier: _fetchingSongs,
              controller: searchController,
              focusNode: _inputNode,
              labelText: '${context.l10n!.search}...',
              onSubmitted: (String value) {
                onSearchSubmitted(value);
                _inputNode.unfocus();
              },
            ),

            // Search History Section (when no results)
            if (!showResults ||
                (_songsSearchResult.isEmpty && _albumsSearchResult.isEmpty))
              Column(
                children: [
                  // History Header with Clear Button
                  if (searchHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Search History',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
                          IconButton(
                            onPressed: clearSearchHistory,
                            icon: Icon(
                              FluentIcons.delete_24_regular,
                              color: primaryColor,
                            ),
                            tooltip: 'Clear History',
                          ),
                        ],
                      ),
                    ),

                  // History List
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: searchHistory.length,
                    itemBuilder: (BuildContext context, int index) {
                      final query = searchHistory[index];
                      final borderRadius =
                          getItemBorderRadius(index, searchHistory.length);

                      return CustomBar(
                        query,
                        FluentIcons.history_24_regular,
                        borderRadius: borderRadius,
                        onTap: () async {
                          searchController.text = query;
                          await performSearch(query);
                          setState(() {
                            showResults = true;
                          });
                          _inputNode.unfocus();
                        },
                        onLongPress: () async {
                          final confirm =
                              await _showConfirmationDialog(context, query) ??
                                  false;
                          if (confirm) {
                            setState(() {
                              searchHistory.remove(query);
                            });
                            await addOrUpdateData(
                                'user', 'searchHistory', searchHistory);
                          }
                        },
                      );
                    },
                  ),
                ],
              )

            // Search Results Section
            else if (showResults)
              Column(
                children: [
                  // Songs Section
                  if (_songsSearchResult.isNotEmpty) ...[
                    SectionTitle(context.l10n!.songs, primaryColor),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _songsSearchResult.length > maxSongsInList
                          ? maxSongsInList
                          : _songsSearchResult.length,
                      itemBuilder: (BuildContext context, int index) {
                        final borderRadius = getItemBorderRadius(
                          index,
                          _songsSearchResult.length > maxSongsInList
                              ? maxSongsInList
                              : _songsSearchResult.length,
                        );

                        return SongBar(
                          _songsSearchResult[index],
                          true,
                          showMusicDuration: true,
                          borderRadius: borderRadius,
                        );
                      },
                    ),
                  ],

                  // Albums Section
                  if (_albumsSearchResult.isNotEmpty) ...[
                    SectionTitle(context.l10n!.albums, primaryColor),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _albumsSearchResult.length > maxSongsInList
                          ? maxSongsInList
                          : _albumsSearchResult.length,
                      itemBuilder: (BuildContext context, int index) {
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
                          playlistArtwork: playlist['image'],
                          cubeIcon: FluentIcons.cd_16_filled,
                          isAlbum: true,
                          borderRadius: borderRadius,
                        );
                      },
                    ),
                  ],

                  // Playlists Section
                  if (_playlistsSearchResult.isNotEmpty) ...[
                    SectionTitle(context.l10n!.playlists, primaryColor),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: commonListViewBottmomPadding,
                      itemCount: _playlistsSearchResult.length > maxSongsInList
                          ? maxSongsInList
                          : _playlistsSearchResult.length,
                      itemBuilder: (BuildContext context, int index) {
                        final playlist = _playlistsSearchResult[index];
                        return PlaylistBar(
                          key: ValueKey(playlist['ytid']),
                          playlist['title'],
                          playlistId: playlist['ytid'],
                          playlistArtwork: playlist['image'],
                          cubeIcon: FluentIcons.apps_list_24_filled,
                        );
                      },
                    ),
                  ],
                ],
              ),
          ],
        ),
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
