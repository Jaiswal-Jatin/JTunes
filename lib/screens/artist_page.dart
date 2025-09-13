import 'package:flutter/material.dart';
import 'package:j3tunes/API/musify.dart' as musify;
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/playlist_page.dart';
import 'package:j3tunes/widgets/mini_player.dart';
import 'package:j3tunes/widgets/playlist_bar.dart';
import 'package:j3tunes/widgets/song_bar.dart';
import 'package:j3tunes/widgets/spinner.dart';
import 'package:audio_service/audio_service.dart';

class ArtistPage extends StatefulWidget {
  final String artistName;

  const ArtistPage({super.key, required this.artistName});

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  late Future<Map<String, List<Map<String, dynamic>>>> _artistDataFuture;

  @override
  void initState() {
    super.initState();
    _artistDataFuture = _fetchArtistData();
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchArtistData() async {
    try {
      // Fetch top songs and playlists/albums concurrently
      final songsFuture = musify.search(widget.artistName, 'song');
      final playlistsFuture = musify.search(widget.artistName, 'playlist');

      final results = await Future.wait([songsFuture, playlistsFuture]);

      return {
        'songs': results[0],
        'playlists': results[1],
      };
    } catch (e) {
      logger.log('Error fetching artist data', e, null);
      return {'songs': [], 'playlists': []};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
      ),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
              future: _artistDataFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Spinner());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Error fetching data'));
                }

                final songs = snapshot.data!['songs'] ?? [];
                final playlists = snapshot.data!['playlists'] ?? [];

                if (songs.isEmpty && playlists.isEmpty) {
                  return const Center(child: Text('No results found'));
                }

                return CustomScrollView(
                  slivers: [
                    if (songs.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Top Songs',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            // Show top 5 songs initially
                            if (index >= 5) return null;
                            return SongBar(songs[index], true);
                          },
                          childCount: songs.length > 5 ? 5 : songs.length,
                        ),
                      ),
                    ],
                    if (playlists.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Albums & Playlists',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final playlist = playlists[index];
                            return PlaylistBar(
                              playlist['title'] ?? 'Unknown Playlist',
                              playlistId: playlist['ytid'],
                              playlistData: playlist,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlaylistPage(
                                      playlistData: playlist,
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          childCount: playlists.length,
                        ),
                      ),
                    ],
                    const SliverToBoxAdapter(child: SizedBox(height: 80)),
                  ],
                );
              },
            ),
          ),
          StreamBuilder<MediaItem?>(
            stream: audioHandler.mediaItem,
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const SizedBox.shrink();
              }
              return MiniPlayer();
            },
          ),
        ],
      ),
    );
  }
}
