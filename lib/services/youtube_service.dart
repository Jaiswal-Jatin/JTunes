import 'package:j3tunes/API/musify.dart' as musify;
import 'package:j3tunes/services/data_manager.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class YoutubeService {
  /// Fetch playlist songs: try YouTube, fallback to musify if YouTube fails or is empty
  Future<List<Map<String, dynamic>>> fetchPlaylistWithFallback(
      String playlistId) async {
    try {
      final ytSongs = await fetchPlaylistVideos(playlistId);
      if (ytSongs.isNotEmpty) return ytSongs;
    } catch (_) {}
    // Fallback to musify
    try {
      final musifySongs = await musify.getSongsFromPlaylist(playlistId);
      if (musifySongs.isNotEmpty) {
        return List<Map<String, dynamic>>.from(musifySongs);
      }
    } catch (_) {}
    return [];
  }

  final YoutubeExplode _yt = YoutubeExplode();

  Future<List<Playlist>> searchPlaylists(String query,
      {int maxResults = 10}) async {
    try {
      var searchResults = await _yt.search.search(query);
      print(
          'searchPlaylists: found \\${searchResults.length} results for "$query"');
      var playlists = searchResults.whereType<Playlist>().toList();
      print('searchPlaylists: filtered to \\${playlists.length} playlists');
      return playlists.take(maxResults).toList();
    } catch (e) {
      print('Error searching playlists: $e');
      return [];
    }
  }

  Future<Video?> fetchVideoDetails(String videoId) async {
    try {
      return await _yt.videos.get(videoId);
    } catch (e) {
      print('Error fetching video details: $e');
      return null;
    }
  }

  Future<String?> fetchAudioStreamUrl(String videoId) async {
    try {
      var manifest = await _yt.videos.streamsClient.getManifest(videoId);
      var audio = manifest.audioOnly.withHighestBitrate();
      return audio.url.toString();
    } catch (e) {
      print('Error fetching audio stream URL: $e');
      return null;
    }
  }

  Future<List<Video>> searchVideos(String query, {int maxResults = 10}) async {
    try {
      var searchResults = await _yt.search.getVideos(query);
      print(
          'searchVideos: found \\${searchResults.length} videos for "$query"');
      return searchResults.take(maxResults).toList();
    } catch (e) {
      print('Error searching videos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchPlaylistVideos(
      String playlistId) async {
    final cacheKey = 'playlist_$playlistId';
    // Try cache first
    final cachedData = await getData('cache', cacheKey);
    if (cachedData != null &&
        cachedData is List &&
        cachedData.isNotEmpty &&
        cachedData[0] is Map) {
      return List<Map<String, dynamic>>.from(cachedData);
    }
    // If not in cache or cache empty, fetch from YouTube
    try {
      final playlistStream = await _yt.playlists.getVideos(playlistId);
      final videos = await playlistStream.toList();
      // Map Video to Map for UI and cache
      final mappedList = videos.map((v) {
        String image = v.thumbnails.highResUrl.isNotEmpty
            ? v.thumbnails.highResUrl
            : v.thumbnails.standardResUrl.isNotEmpty
                ? v.thumbnails.standardResUrl
                : v.thumbnails.mediumResUrl.isNotEmpty
                    ? v.thumbnails.mediumResUrl
                    : v.thumbnails.lowResUrl;
        if (image.isEmpty || image.endsWith('/hqdefault.jpg')) {
          image = 'assets/images/JTunes.png';
        }
        return {
          'ytid': v.id.value,
          'title': v.title,
          'image': image,
          'artist': v.author,
          'description': v.description,
          'duration': v.duration?.inSeconds ?? 0,
        };
      }).toList();
      // Cache the result for future use
      await addOrUpdateData('cache', cacheKey, mappedList);
      return mappedList;
    } catch (e) {
      print('Error fetching playlist videos: $e');
      return [];
    }
  }
}
