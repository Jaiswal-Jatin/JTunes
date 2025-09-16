import 'dart:async';
import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
// import 'package:home_widget/home_widget.dart'; // Commented out as MusicWidgetExtension is not used for iOS
import 'package:j3tunes/main.dart';
import 'package:j3tunes/models/position_data.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:rxdart/rxdart.dart';

// class MusicWidgetService { // Commented out as MusicWidgetExtension is not used for iOS
//   factory MusicWidgetService() => _instance;
//   MusicWidgetService._internal();
//   static final MusicWidgetService _instance = MusicWidgetService._internal();

//   final _colorCache = <String, int>{};

//   void init() {
//     // Listen to all relevant streams from audio_service
//     Rx.combineLatest3(
//       audioHandler.mediaItem,
//       audioHandler.playbackState,
//       audioHandler.positionDataStream,
//       (a, b, c) => {'item': a, 'state': b, 'pos': c},
//     )
//         .throttleTime(const Duration(seconds: 1),
//             trailing: true) // Update at most once per second
//         .listen((data) {
//       final mediaItem = data['item'] as MediaItem?;
//       final playbackState = data['state'] as PlaybackState?;
//       final positionData = data['pos'] as PositionData?;

//       if (mediaItem != null && playbackState != null && positionData != null) {
//         updateWidget(
//           mediaItem: mediaItem,
//           playbackState: playbackState,
//           position: positionData.position,
//           duration: positionData.duration,
//         );
//       }
//     });
//   }

//   Future<void> updateWidget({
//     required MediaItem mediaItem,
//     required PlaybackState playbackState,
//     required Duration position,
//     required Duration duration,
//   }) async {
//     final artworkPath = await _getCachedArtworkPath(mediaItem);

//     await HomeWidget.saveWidgetData<String>('title', mediaItem.title);
//     await HomeWidget.saveWidgetData<String>('artist', mediaItem.artist ?? '');
//     await HomeWidget.saveWidgetData<String>('artwork_path', artworkPath);
//     await HomeWidget.saveWidgetData<bool>('is_playing', playbackState.playing);
//     await HomeWidget.saveWidgetData<int>('duration', duration.inMilliseconds);
//     await HomeWidget.saveWidgetData<int>('position', position.inMilliseconds);
//     await HomeWidget.updateWidget(
//       name: 'MusicWidgetProvider',
//       androidName: 'MusicWidgetProvider',
//     );
//   }

//   Future<String?> _getCachedArtworkPath(MediaItem mediaItem) async {
//     final artUri = mediaItem.artUri;
//     if (artUri == null) return null;

//     // If it's already a local file (from offline songs), just return the path
//     if (artUri.scheme == 'file') {
//       return artUri.toFilePath();
//     }

//     // If it's a network image, download and cache it
//     if (artUri.scheme == 'http' || artUri.scheme == 'https') {
//       try {
//         final file =
//             await DefaultCacheManager().getSingleFile(artUri.toString());
//         return file.path;
//       } catch (e) {
//         logger.log('Error caching artwork for widget', e, null);
//         return null;
//       }
//     }
//     return null;
//   }
// }

/// A placeholder widget. The actual widget is rendered on the Android side.
class MusicWidget extends StatelessWidget {
  const MusicWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: const Text('This is a placeholder for the music widget.'),
    );
  }
}
