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

import 'package:audio_service/audio_service.dart';

Map mediaItemToMap(MediaItem mediaItem) => {
      'id': mediaItem.id,
      'ytid': mediaItem.extras!['ytid'],
      'album': mediaItem.album.toString(),
      'artist': mediaItem.artist.toString(),
      'title': mediaItem.title,
      'highResImage': mediaItem.extras?['highResImage'] ?? mediaItem.artUri.toString(),
      'lowResImage': mediaItem.extras!['lowResImage'],
      'isLive': mediaItem.extras!['isLive'],
    };

MediaItem mapToMediaItem(Map song) {
  // Determine the best image URL to use
  String? bestImageUrl;
  
  // Priority: highResImage > lowResImage > fallback
  final highResImage = song['highResImage']?.toString();
  final lowResImage = song['lowResImage']?.toString();
  
  if (highResImage != null && highResImage.isNotEmpty && highResImage != 'null') {
    bestImageUrl = highResImage;
  } else if (lowResImage != null && lowResImage.isNotEmpty && lowResImage != 'null') {
    bestImageUrl = lowResImage;
  }
  
  return MediaItem(
    id: song['id'].toString(),
    album: '',
    artist: song['artist'].toString().trim(),
    title: song['title'].toString(),
    artUri: song['isOffline'] ?? false
        ? Uri.file(bestImageUrl ?? '')
        : Uri.parse(bestImageUrl ?? ''),
    duration:
        song['duration'] != null ? Duration(seconds: song['duration']) : null,
    extras: {
      'lowResImage': song['lowResImage'],
      'highResImage': song['highResImage'], // Ensure highResImage is preserved
      'ytid': song['ytid'],
      'isLive': song['isLive'],
      'isOffline': song['isOffline'],
      'artWorkPath': bestImageUrl ?? song['highResImage']?.toString() ?? '',
    },
  );
}
