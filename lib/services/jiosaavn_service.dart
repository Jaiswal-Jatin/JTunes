import 'package:jiosaavn/jiosaavn.dart';

class JioSaavnService {
  final JioSaavnClient _client = JioSaavnClient();

  Future<List<dynamic>> fetchHomeSongs() async {
    // Use 'all' to get trending songs (top results)
    final result = await _client.search.all('trending');
    return result.songs.results;
  }

  Future<List<dynamic>> fetchPlaylists() async {
    // Use 'all' to get featured playlists (top results)
    final result = await _client.search.all('featured');
    return result.playlists.results;
  }

  Future<List<dynamic>> fetchAlbums() async {
    // Use 'all' to get albums (top results)
    final result = await _client.search.all('albums');
    return result.albums.results;
  }

  Future<List<dynamic>> searchSongs(String query) async {
    final result = await _client.search.songs(query);
    return result.results;
  }

  Future<List<dynamic>> searchPlaylists(String query) async {
    final result = await _client.search.all(query);
    return result.playlists.results;
  }

  Future<List<dynamic>> searchAlbums(String query) async {
    final result = await _client.search.albums(query);
    return result.results;
  }
}
