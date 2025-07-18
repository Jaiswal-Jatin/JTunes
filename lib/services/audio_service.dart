// ignore_for_file: directives_ordering, override_on_non_overriding_member, unnecessary_null_comparison, require_trailing_commas, unnecessary_null_in_if_null_operators

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
import 'dart:io';

import 'package:j3tunes/API/musify.dart';
import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/models/position_data.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/services/music_service.dart';
import 'package:j3tunes/utilities/mediaitem.dart';
import 'package:rxdart/rxdart.dart';

class J3TunesAudioHandler extends BaseAudioHandler {
  Future<ClippingAudioSource?> checkIfSponsorBlockIsAvailable(
    UriAudioSource audioSource,
    String songId,
  ) async {
    try {
      final segments = await getSkipSegments(songId);
      if (segments.isNotEmpty && segments[0]['end'] != null) {
        return ClippingAudioSource(
          child: audioSource,
          start: Duration.zero,
          end: Duration(seconds: segments[0]['end']!),
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error checking sponsor block', e, stackTrace);
    }
    return null;
  }

  // Track if currently playing a playlist
  bool _isPlaylistMode = false;
  String? _currentPlaylistId;

  J3TunesAudioHandler() {
    _setupEventSubscriptions();
    _updatePlaybackState();

    audioPlayer.setAndroidAudioAttributes(
      const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
    );

    _initialize();
  }

  final AudioPlayer audioPlayer = AudioPlayer(
    audioLoadConfiguration: const AudioLoadConfiguration(
      androidLoadControl: AndroidLoadControl(
        maxBufferDuration: Duration(seconds: 60),
        bufferForPlaybackDuration: Duration(milliseconds: 500),
        bufferForPlaybackAfterRebufferDuration: Duration(seconds: 3),
      ),
    ),
  );

  Timer? _sleepTimer;
  bool sleepTimerExpired = false;

  final List<Map> _queueList = [];
  final List<Map> _historyList = [];
  int _currentQueueIndex = 0;
  bool _isLoadingNextSong = false;
  bool _isCreatingAutoPlaylist = false;

  // Error handling
  String? _lastError;
  int _consecutiveErrors = 0;
  static const int _maxConsecutiveErrors = 3;

  // Performance constants
  static const int _maxHistorySize = 50;
  static const int _queueLookahead = 3;
  static const Duration _errorRetryDelay = Duration(seconds: 2);
  static const Duration _songTransitionTimeout = Duration(seconds: 30);

  Stream<PositionData> get positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
        audioPlayer.positionStream,
        audioPlayer.bufferedPositionStream,
        audioPlayer.durationStream,
        (position, bufferedPosition, duration) =>
            PositionData(position, bufferedPosition, duration ?? Duration.zero),
      ).distinct((prev, curr) {
        // Reduce stream updates for better performance
        return (prev.position.inSeconds - curr.position.inSeconds).abs() < 1 &&
            prev.duration == curr.duration;
      });

  final processingStateMap = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _setupEventSubscriptions() {
    audioPlayer.playbackEventStream.listen(_handlePlaybackEvent);

    audioPlayer.durationStream.listen((duration) {
      _updatePlaybackState();
      if (_currentQueueIndex < _queueList.length && duration != null) {
        _updateCurrentMediaItemWithDuration(duration);
      }
    });

    audioPlayer.currentIndexStream.listen((index) {
      _updatePlaybackState();
    });

    audioPlayer.sequenceStateStream.listen((state) {
      _updatePlaybackState();
    });

    // Listen for player errors
    audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.idle &&
          !state.playing &&
          _lastError != null) {
        _handlePlaybackError();
      }
    });
  }

  void _updateCurrentMediaItemWithDuration(Duration duration) {
    try {
      final currentSong = _queueList[_currentQueueIndex];
      final currentMediaItem = mapToMediaItem(currentSong);
      mediaItem.add(currentMediaItem.copyWith(duration: duration));

      final mediaItems = _queueList.asMap().entries.map((entry) {
        final song = entry.value;
        final mediaItem = mapToMediaItem(song);
        return entry.key == _currentQueueIndex
            ? mediaItem.copyWith(duration: duration)
            : mediaItem;
      }).toList();

      queue.add(mediaItems);
    } catch (e, stackTrace) {
      logger.log('Error updating media item with duration', e, stackTrace);
    }
  }

  Future<void> _initialize() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());
    } catch (e, stackTrace) {
      logger.log('Error initializing audio session', e, stackTrace);
    }
  }

  void _updatePlaybackState() {
    try {
      final currentState = playbackState.valueOrNull;
      final newProcessingState =
          processingStateMap[audioPlayer.processingState] ??
              AudioProcessingState.idle;

      // Only update if state actually changed to reduce rebuilds
      if (currentState == null ||
          currentState.playing != audioPlayer.playing ||
          currentState.processingState != newProcessingState ||
          currentState.queueIndex != _currentQueueIndex) {
        playbackState.add(
          PlaybackState(
            controls: [
              MediaControl.skipToPrevious,
              if (audioPlayer.playing)
                MediaControl.pause
              else
                MediaControl.play,
              MediaControl.stop,
              MediaControl.skipToNext,
            ],
            systemActions: const {
              MediaAction.seek,
              MediaAction.seekForward,
              MediaAction.seekBackward,
            },
            androidCompactActionIndices: const [0, 1, 3],
            processingState: newProcessingState,
            playing: audioPlayer.playing,
            updatePosition: audioPlayer.position,
            bufferedPosition: audioPlayer.bufferedPosition,
            speed: audioPlayer.speed,
            queueIndex: _currentQueueIndex < _queueList.length
                ? _currentQueueIndex
                : null,
            updateTime: DateTime.now(),
          ),
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error updating playback state', e, stackTrace);
    }
  }

  void _handlePlaybackEvent(PlaybackEvent event) {
    try {
      if (event.processingState == ProcessingState.completed &&
          !sleepTimerExpired) {
        Future.delayed(
          const Duration(milliseconds: 100),
          _handleSongCompletion,
        );
      }
      _updatePlaybackState();
    } catch (e, stackTrace) {
      logger.log('Error handling playback event', e, stackTrace);
    }
  }

  void _handlePlaybackError() {
    _consecutiveErrors++;
    logger.log(
      'Playback error occurred. Consecutive errors: $_consecutiveErrors',
      _lastError,
      null,
    );

    if (_consecutiveErrors >= _maxConsecutiveErrors) {
      logger.log(
        'Max consecutive errors reached. Stopping playback.',
        null,
        null,
      );
      stop();
      return;
    }

    // Try to skip to next song if available
    if (hasNext) {
      Future.delayed(_errorRetryDelay, skipToNext);
    }
  }

  Future<void> _handleSongCompletion() async {
    try {
      if (_currentQueueIndex < _queueList.length) {
        _addToHistory(_queueList[_currentQueueIndex]);
      }

      // Check repeat mode first
      if (repeatNotifier.value == AudioServiceRepeatMode.one) {
        print('[AudioHandler] Repeat one mode, playing again');
        await playAgain();
        return;
      }

      // Check if there's a next song in queue
      if (_currentQueueIndex < _queueList.length - 1) {
        print('[AudioHandler] Playing next song in queue');
        await _playFromQueue(_currentQueueIndex + 1);
        return;
      }

      // Check repeat all mode
      if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        print('[AudioHandler] Repeat all mode, playing first song');
        await _playFromQueue(0);
        return;
      }

      // Auto-play next song if enabled
      if (playNextSongAutomatically.value) {
        print('[AudioHandler] Auto-playing next recommended song');
        await _handleAutoPlayNext();
      } else {
        print('[AudioHandler] Song completed, no auto-play');
      }
    } catch (e, stackTrace) {
      logger.log('Error handling song completion', e, stackTrace);
    }
  }

  Future<void> _handleAutoPlayNext() async {
    if (_isLoadingNextSong) {
      print('[AudioHandler] Already loading next song, skipping');
      return;
    }

    _isLoadingNextSong = true;
    print('[AudioHandler] Starting auto-play next song process');

    try {
      // If queue has more songs, play next from queue
      if (_currentQueueIndex < _queueList.length - 1) {
        print('[AudioHandler] Playing next song from existing queue');
        await _playFromQueue(_currentQueueIndex + 1);
        return;
      }

      // If queue is small, create more songs
      if (_queueList.length <= 3) {
        print('[AudioHandler] Queue is small, creating auto-playlist');
        final currentSong = _currentQueueIndex < _queueList.length
            ? _queueList[_currentQueueIndex]
            : null;
        if (currentSong != null) {
          await _createAutoPlaylist(currentSong['ytid']);
          // After creating playlist, play next song if available
          if (_currentQueueIndex < _queueList.length - 1) {
            await _playFromQueue(_currentQueueIndex + 1);
          }
        }
        return;
      }

      // Fallback: Get single similar song
      final currentMediaItem = mediaItem.valueOrNull;
      if (currentMediaItem == null) {
        print('[AudioHandler] No current media item for auto-play');
        return;
      }

      final currentYtid = currentMediaItem.extras?['ytid'];
      if (currentYtid == null) {
        print('[AudioHandler] No ytid in current media item');
        return;
      }

      print('[AudioHandler] Getting single similar song for: $currentYtid');

      // Clear any existing recommendation first
      nextRecommendedSong = null;

      // Get similar song
      getSimilarSong(currentYtid);

      // Wait for recommendation with timeout
      final maxWaitTime = DateTime.now().add(const Duration(seconds: 8));
      while (
          nextRecommendedSong == null && DateTime.now().isBefore(maxWaitTime)) {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      if (nextRecommendedSong != null) {
        print(
            '[AudioHandler] Playing recommended song: ${nextRecommendedSong!['title']}');
        final recommendedSong = Map<String, dynamic>.from(nextRecommendedSong!);
        nextRecommendedSong = null;

        // Play the recommended song
        await playSong(recommendedSong);
      } else {
        print('[AudioHandler] No recommended song found after waiting');
      }
    } catch (e, stackTrace) {
      logger.log('Error in _handleAutoPlayNext', e, stackTrace);
    } finally {
      _isLoadingNextSong = false;
      print('[AudioHandler] Auto-play process completed');
    }
  }

  Future<void> _createAutoPlaylist(String seedSongId) async {
    if (_isCreatingAutoPlaylist) {
      print('[AudioHandler] Already creating auto-playlist, skipping');
      return;
    }

    _isCreatingAutoPlaylist = true;
    print('[AudioHandler] Creating auto-playlist for seed song: $seedSongId');

    try {
      final List<Map> newSongs = [];
      String currentSeedId = seedSongId;

      // Get 8-10 similar songs to create a proper playlist
      for (int i = 0; i < 8; i++) {
        try {
          print('[AudioHandler] Getting similar song $i for: $currentSeedId');

          // Clear previous recommendation
          nextRecommendedSong = null;

          // Get similar song
          getSimilarSong(currentSeedId);

          // Wait for recommendation with shorter timeout
          final maxWaitTime = DateTime.now().add(const Duration(seconds: 4));
          while (nextRecommendedSong == null &&
              DateTime.now().isBefore(maxWaitTime)) {
            await Future.delayed(const Duration(milliseconds: 200));
          }

          if (nextRecommendedSong != null) {
            final similarSong = Map<String, dynamic>.from(nextRecommendedSong!);

            // Check if song is not already in queue or new songs list
            final isDuplicate =
                _queueList.any((s) => s['ytid'] == similarSong['ytid']) ||
                    newSongs.any((s) => s['ytid'] == similarSong['ytid']);

            if (!isDuplicate) {
              newSongs.add(similarSong);
              print(
                  '[AudioHandler] Added to auto-playlist: ${similarSong['title']}');

              // Use this song as seed for next recommendation (chain effect)
              currentSeedId = similarSong['ytid'];
            } else {
              print(
                  '[AudioHandler] Skipping duplicate song: ${similarSong['title']}');
            }

            nextRecommendedSong = null;
          } else {
            print('[AudioHandler] No similar song found for iteration $i');
          }

          // Small delay between requests to avoid rate limiting
          await Future.delayed(const Duration(milliseconds: 300));
        } catch (e) {
          print('[AudioHandler] Error getting similar song $i: $e');
          continue;
        }
      }

      // Add all new songs to queue
      if (newSongs.isNotEmpty) {
        print('[AudioHandler] Adding ${newSongs.length} songs to queue');
        _queueList.addAll(newSongs);
        _updateQueueMediaItems();
        print(
            '[AudioHandler] Auto-playlist created! Total queue length: ${_queueList.length}');
      } else {
        print('[AudioHandler] No new songs found for auto-playlist');
      }
    } catch (e, stackTrace) {
      logger.log('Error creating auto-playlist', e, stackTrace);
    } finally {
      _isCreatingAutoPlaylist = false;
    }
  }

  void _addToHistory(Map song) {
    try {
      _historyList
        ..removeWhere((s) => s['ytid'] == song['ytid'])
        ..insert(0, song);

      if (_historyList.length > _maxHistorySize) {
        _historyList.removeRange(_maxHistorySize, _historyList.length);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding to history', e, stackTrace);
    }
  }

  Future<void> addToQueue(Map song, {bool playNext = false}) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data for queue', null, null);
        return;
      }

      _queueList.removeWhere((s) => s['ytid'] == song['ytid']);

      if (playNext) {
        final insertIndex = _currentQueueIndex + 1;
        if (insertIndex < _queueList.length) {
          _queueList.insert(insertIndex, song);
        } else {
          _queueList.add(song);
        }
      } else {
        _queueList.add(song);
      }

      _updateQueueMediaItems();

      if (!audioPlayer.playing && _queueList.length == 1) {
        await _playFromQueue(0);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding to queue', e, stackTrace);
    }
  }

  Future<void> addPlaylistToQueue(
    List<Map> songs, {
    bool replace = false,
    int? startIndex,
  }) async {
    try {
      if (replace) {
        _queueList.clear();
        _currentQueueIndex = 0;
      }

      for (final song in songs) {
        if (song['ytid'] != null && song['ytid'].toString().isNotEmpty) {
          _queueList
            ..removeWhere((s) => s['ytid'] == song['ytid'])
            ..add(song);
        }
      }

      _updateQueueMediaItems();

      if (startIndex != null && startIndex < _queueList.length) {
        await _playFromQueue(startIndex);
      } else if (replace && _queueList.isNotEmpty) {
        await _playFromQueue(0);
      }
    } catch (e, stackTrace) {
      logger.log('Error adding playlist to queue', e, stackTrace);
    }
  }

  Future<void> removeFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) return;

      _queueList.removeAt(index);

      if (index < _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (index == _currentQueueIndex && _queueList.isNotEmpty) {
        if (_currentQueueIndex >= _queueList.length) {
          _currentQueueIndex = _queueList.length - 1;
        }
        await _playFromQueue(_currentQueueIndex);
      }

      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error removing from queue', e, stackTrace);
    }
  }

  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    try {
      if (oldIndex < 0 ||
          oldIndex >= _queueList.length ||
          newIndex < 0 ||
          newIndex >= _queueList.length) return;

      final song = _queueList.removeAt(oldIndex);
      _queueList.insert(newIndex, song);

      if (oldIndex == _currentQueueIndex) {
        _currentQueueIndex = newIndex;
      } else if (oldIndex < _currentQueueIndex &&
          newIndex >= _currentQueueIndex) {
        _currentQueueIndex--;
      } else if (oldIndex > _currentQueueIndex &&
          newIndex <= _currentQueueIndex) {
        _currentQueueIndex++;
      }

      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error reordering queue', e, stackTrace);
    }
  }

  void clearQueue() {
    try {
      _queueList.clear();
      _currentQueueIndex = 0;
      _updateQueueMediaItems();
    } catch (e, stackTrace) {
      logger.log('Error clearing queue', e, stackTrace);
    }
  }

  void _updateQueueMediaItems() {
    try {
      final mediaItems = _queueList.map(mapToMediaItem).toList();
      queue.add(mediaItems);

      if (_currentQueueIndex < mediaItems.length) {
        mediaItem.add(mediaItems[_currentQueueIndex]);
      }
    } catch (e, stackTrace) {
      logger.log('Error updating queue media items', e, stackTrace);
    }
  }

  Future<void> _playFromQueue(int index) async {
    try {
      if (index < 0 || index >= _queueList.length) {
        logger.log('Invalid queue index: $index', null, null);
        return;
      }

      _currentQueueIndex = index;

      // UI ko turant update karo (song bar me show ho)
      final mediaItems = _queueList.map(mapToMediaItem).toList();
      queue.add(mediaItems);
      if (_currentQueueIndex < mediaItems.length) {
        mediaItem.add(mediaItems[_currentQueueIndex]);
      }

      // Ab song ko load/play karo
      final success = await _playSongInternal(_queueList[index]);

      if (success) {
        _consecutiveErrors = 0; // Reset error counter on success
        _preloadUpcomingSongs();
      } else {
        _handlePlaybackError();
      }
    } catch (e, stackTrace) {
      logger.log('Error playing from queue', e, stackTrace);
      _handlePlaybackError();
    }
  }

  void _preloadUpcomingSongs() {
    // Don't block UI - run preloading in background without awaiting
    Future.microtask(() async {
      try {
        final preloadTasks = <Future<void>>[];

        for (var i = 1; i <= _queueLookahead; i++) {
          final nextIndex = _currentQueueIndex + i;
          if (nextIndex < _queueList.length) {
            final nextSong = _queueList[nextIndex];
            if (nextSong['ytid'] != null && !(nextSong['isOffline'] ?? false)) {
              // Create preload task with timeout and error handling
              final preloadTask = _preloadSingleSong(nextSong).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  logger.log(
                    'Preload timeout for song ${nextSong['ytid']}',
                    null,
                    null,
                  );
                },
              ).catchError((e) {
                // Silently catch and log preload errors to prevent UI lag
                logger.log(
                  'Error preloading song ${nextSong['ytid']}',
                  e,
                  null,
                );
              });

              preloadTasks.add(preloadTask);
            }
          }
        }

        // Run all preload tasks concurrently with overall timeout
        if (preloadTasks.isNotEmpty) {
          await Future.wait(preloadTasks).timeout(
            const Duration(seconds: 15),
            onTimeout: () {
              logger.log('Preloading batch timeout', null, null);
              return <void>[];
            },
          ).catchError((e) {
            logger.log('Error in preload batch', e, null);
            return <void>[];
          });
        }
      } catch (e, stackTrace) {
        logger.log('Error in _preloadUpcomingSongs', e, stackTrace);
      }
    });
  }

  Future<void> _preloadSingleSong(Map nextSong) async {
    try {
      final cacheKey =
          'song_${nextSong['ytid']}_${audioQualitySetting.value}_url';

      // Check if already cached
      final cachedUrl = getData('cache', cacheKey);
      if (cachedUrl.toString().isNotEmpty) {
        return; // Already cached, skip
      }

      final url = await getSong(nextSong['ytid'], nextSong['isLive'] ?? false);
      if (url != null && url.isNotEmpty) {
        await addOrUpdateData('cache', cacheKey, url);
        logger.log(
          'Successfully preloaded song ${nextSong['ytid']}',
          null,
          null,
        );
      }
    } catch (e) {
      // Don't rethrow - let parent handle
      logger.log('Failed to preload song ${nextSong['ytid']}: $e', null, null);
    }
  }

  // Getters
  List<Map> get currentQueue => List.unmodifiable(_queueList);
  List<Map> get playHistory => List.unmodifiable(_historyList);
  int get currentQueueIndex => _currentQueueIndex;
  Map? get currentSong => _currentQueueIndex < _queueList.length
      ? _queueList[_currentQueueIndex]
      : null;

  bool get hasNext {
    // Always show next button as enabled if auto-play is on or there are more songs in queue
    return _currentQueueIndex < _queueList.length - 1 ||
        playNextSongAutomatically.value ||
        repeatNotifier.value != AudioServiceRepeatMode.none;
  }

  bool get hasPrevious {
    // Always show previous button as enabled if there are previous songs or history
    return _currentQueueIndex > 0 ||
        _historyList.isNotEmpty ||
        repeatNotifier.value != AudioServiceRepeatMode.none;
  }

  @override
  Future<void> onTaskRemoved() async {
    try {
      if (!backgroundPlay.value) {
        await stop();
        final session = await AudioSession.instance;
        await session.setActive(false);
      }
    } catch (e, stackTrace) {
      logger.log('Error in onTaskRemoved', e, stackTrace);
    }
    await super.onTaskRemoved();
  }

  @override
  Future<void> play() async {
    try {
      await audioPlayer.play();
    } catch (e, stackTrace) {
      logger.log('Error in play()', e, stackTrace);
      _lastError = e.toString();
    }
  }

  @override
  Future<void> pause() async {
    try {
      await audioPlayer.pause();
    } catch (e, stackTrace) {
      logger.log('Error in pause()', e, stackTrace);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await audioPlayer.stop();
      _lastError = null;
      _consecutiveErrors = 0;
    } catch (e, stackTrace) {
      logger.log('Error in stop()', e, stackTrace);
    }
  }

  @override
  Future<void> seek(Duration position) async {
    try {
      await audioPlayer.seek(position);
    } catch (e, stackTrace) {
      logger.log('Error in seek()', e, stackTrace);
    }
  }

  @override
  Future<void> fastForward() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds + 15));

  @override
  Future<void> rewind() =>
      seek(Duration(seconds: audioPlayer.position.inSeconds - 15));

  Future<bool> playSong(Map song) async {
    try {
      if (song['ytid'] == null || song['ytid'].toString().isEmpty) {
        logger.log('Invalid song data: missing ytid', null, null);
        return false;
      }

      print('[AudioHandler] Playing song: ${song['title']} (${song['ytid']})');

      // First add song to queue if not already present
      final existingIndex =
          _queueList.indexWhere((s) => s['ytid'] == song['ytid']);
      if (existingIndex == -1) {
        _queueList.add(song);
        _currentQueueIndex = _queueList.length - 1;
        print(
            '[AudioHandler] Added song to queue. New queue length: ${_queueList.length}, Current index: $_currentQueueIndex');
      } else {
        _currentQueueIndex = existingIndex;
        print(
            '[AudioHandler] Song already in queue at index: $_currentQueueIndex');
      }

      // Update UI immediately
      _updateQueueMediaItems();

      // Now play the song
      final success = await _playSongInternal(song);

      if (success) {
        _consecutiveErrors = 0;
        _preloadUpcomingSongs();

        // Create auto-playlist immediately if auto-play is enabled and queue is small
        if (playNextSongAutomatically.value && _queueList.length <= 2) {
          print(
              '[AudioHandler] Triggering auto-playlist creation for continuous playback');
          // Don't wait, create playlist immediately in background
          _createAutoPlaylist(song['ytid']);
        }
      }

      return success;
    } catch (e, stackTrace) {
      logger.log('Error playing song', e, stackTrace);
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> _playSongInternal(Map song) async {
    try {
      _lastError = null;
      final isOffline = song['isOffline'] ?? false;

      if (audioPlayer.playing) await audioPlayer.stop();

      final songUrl = await _getSongUrl(song, isOffline);

      if (songUrl == null || songUrl.isEmpty) {
        logger.log('Failed to get song URL for ${song['ytid']}', null, null);
        _lastError = 'Failed to get song URL';
        return false;
      }

      final audioSource = await buildAudioSource(song, songUrl, isOffline);
      if (audioSource == null) {
        logger.log(
          'Failed to build audio source for ${song['ytid']}',
          null,
          null,
        );
        _lastError = 'Failed to build audio source';
        return false;
      }

      final success = await _setAudioSourceAndPlay(
        song,
        audioSource,
        songUrl,
        isOffline,
      );

      return success;
    } catch (e, stackTrace) {
      logger.log('Error in _playSongInternal', e, stackTrace);
      _lastError = e.toString();
      return false;
    }
  }

  Future<String?> _getSongUrl(Map song, bool isOffline) async {
    if (isOffline) {
      return _getOfflineSongUrl(song);
    } else {
      // Use new MusicServices API for online song
      try {
        final musicService = MusicServices();
        final songId = song['ytid'] ?? song['videoId'];
        if (songId == null) {
          logger.log('Song ID is null for song: $song', null, null);
          return null;
        }
        final playlistData =
            await musicService.getWatchPlaylist(videoId: songId);
        logger.log(
            'getWatchPlaylist response for $songId: $playlistData', null, null);
        if (playlistData != null && playlistData['tracks'].isNotEmpty) {
          final track = playlistData['tracks'][0];
          logger.log('Track info for $songId: $track', null, null);
          // Try to get stream URL from track
          final url = track['streamUrl'] ?? track['url'] ?? null;
          logger.log('Fetched stream URL for $songId: $url', null, null);
          if (url != null && url.isNotEmpty) {
            return url;
          }
        } else {
          logger.log('No tracks found in playlistData for $songId', null, null);
        }
        // Fallback to musify.dart getSong if MusicServices fails
        logger.log('Trying musify.getSong fallback for $songId', null, null);
        final fallbackUrl = await getSong(songId, song['isLive'] ?? false);
        logger.log('musify.getSong fallback URL for $songId: $fallbackUrl',
            null, null);
        return fallbackUrl;
      } catch (e) {
        logger.log(
            'Exception in _getSongUrl for song: $song, error: $e', null, null);
        // Fallback to musify.dart getSong if MusicServices throws error
        final songId = song['ytid'] ?? song['videoId'];
        logger.log('Trying musify.getSong fallback after exception for $songId',
            null, null);
        if (songId != null) {
          final fallbackUrl = await getSong(songId, song['isLive'] ?? false);
          logger.log('musify.getSong fallback URL for $songId: $fallbackUrl',
              null, null);
          return fallbackUrl;
        }
        return null;
      }
    }
  }

  Future<String?> _getOfflineSongUrl(Map song) async {
    final audioPath = song['audioPath'];
    if (audioPath == null || audioPath.isEmpty) {
      logger.log(
        'Missing audioPath for offline song: ${song['ytid']}',
        null,
        null,
      );
      return null;
    }

    final file = File(audioPath);
    if (!await file.exists()) {
      logger.log('Offline audio file not found: $audioPath', null, null);

      // Try to find in userOfflineSongs
      final offlineSong = userOfflineSongs.firstWhere(
        (s) => s['ytid'] == song['ytid'],
        orElse: () => <String, dynamic>{},
      );

      if (offlineSong.isNotEmpty && offlineSong['audioPath'] != null) {
        final fallbackFile = File(offlineSong['audioPath']);
        if (await fallbackFile.exists()) {
          song['audioPath'] = offlineSong['audioPath'];
          return offlineSong['audioPath'];
        }
      }

      // Fallback to online
      return getSong(song['ytid'], song['isLive'] ?? false);
    }

    return audioPath;
  }

  Future<bool> _setAudioSourceAndPlay(
    Map song,
    AudioSource audioSource,
    String songUrl,
    bool isOffline,
  ) async {
    try {
      await audioPlayer
          .setAudioSource(audioSource)
          .timeout(_songTransitionTimeout);
      await Future.delayed(const Duration(milliseconds: 100));

      if (audioPlayer.duration != null) {
        final currentMediaItem = mapToMediaItem(song);
        mediaItem.add(
          currentMediaItem.copyWith(duration: audioPlayer.duration),
        );
      }

      await audioPlayer.play();

      if (!isOffline) {
        final cacheKey =
            'song_${song['ytid']}_${audioQualitySetting.value}_url';
        unawaited(addOrUpdateData('cache', cacheKey, songUrl));
      }

      _updatePlaybackState();

      if (playNextSongAutomatically.value) {
        getSimilarSong(song['ytid']);
      }

      // Start preloading AFTER current song is playing to avoid blocking
      Future.delayed(const Duration(seconds: 2), _preloadUpcomingSongs);

      return true;
    } catch (e, stackTrace) {
      logger.log('Error setting audio source', e, stackTrace);

      // Try online fallback for offline songs
      if (isOffline) {
        logger.log('Attempting to play online version as fallback', null, null);
        final onlineUrl = await getSong(song['ytid'], song['isLive'] ?? false);
        if (onlineUrl != null && onlineUrl.isNotEmpty) {
          final onlineSource = await buildAudioSource(song, onlineUrl, false);
          if (onlineSource != null) {
            try {
              await audioPlayer
                  .setAudioSource(onlineSource)
                  .timeout(_songTransitionTimeout);
              await Future.delayed(const Duration(milliseconds: 100));

              if (audioPlayer.duration != null) {
                final currentMediaItem = mapToMediaItem(song);
                mediaItem.add(
                  currentMediaItem.copyWith(duration: audioPlayer.duration),
                );
              }

              await audioPlayer.play();
              _updatePlaybackState();

              // Start preloading after successful fallback
              Future.delayed(const Duration(seconds: 2), _preloadUpcomingSongs);

              return true;
            } catch (fallbackError, fallbackStackTrace) {
              logger.log(
                'Fallback also failed',
                fallbackError,
                fallbackStackTrace,
              );
            }
          }
        }
      }

      _lastError = e.toString();
      return false;
    }
  }

  Future<void> playNext(Map song) async {
    await addToQueue(song, playNext: true);
  }

  Future<void> playPlaylistSong({
    Map<dynamic, dynamic>? playlist,
    required int songIndex,
  }) async {
    try {
      if (playlist != null && playlist['list'] != null) {
        _isPlaylistMode = true;
        _currentPlaylistId = playlist['ytid']?.toString();
        await addPlaylistToQueue(
          List<Map>.from(playlist['list']),
          replace: true,
          startIndex: songIndex,
        );
      }
    } catch (e, stackTrace) {
      logger.log('Error playing playlist', e, stackTrace);
    }
  }

  Future<AudioSource?> buildAudioSource(
    Map song,
    String songUrl,
    bool isOffline,
  ) async {
    try {
      final tag = mapToMediaItem(song);

      if (isOffline) {
        return AudioSource.file(songUrl, tag: tag);
      }

      final uri = Uri.parse(songUrl);
      final audioSource = AudioSource.uri(uri, tag: tag);

      if (!sponsorBlockSupport.value) {
        return audioSource;
      }

      final spbAudioSource = await checkIfSponsorBlockIsAvailable(
        audioSource,
        song['ytid'],
      );
      return spbAudioSource ?? audioSource;
    } catch (e, stackTrace) {
      logger.log('Error building audio source', e, stackTrace);
      return null;
    }
  }

  Future<void> skipToSong(int newIndex) async {
    try {
      if (newIndex < 0 || newIndex >= _queueList.length) {
        logger.log('Invalid song index: $newIndex', null, null);
        return;
      }
      await _playFromQueue(newIndex);
    } catch (e, stackTrace) {
      logger.log('Error skipping to song', e, stackTrace);
    }
  }

  @override
  Future<void> skipToNext() async {
    try {
      print(
          '[AudioHandler] skipToNext called. Current index: $_currentQueueIndex, Queue length: ${_queueList.length}');

      if (repeatNotifier.value == AudioServiceRepeatMode.one) {
        print('[AudioHandler] Repeat one mode, playing again');
        await playAgain();
        return;
      }

      // If there's a next song in queue, play it
      if (_currentQueueIndex < _queueList.length - 1) {
        print('[AudioHandler] Playing next song in queue');
        await _playFromQueue(_currentQueueIndex + 1);
        return;
      }

      // If repeat all is enabled and we have songs in queue
      if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        print('[AudioHandler] Repeat all mode, playing first song');
        await _playFromQueue(0);
        return;
      }

      // Auto-play next song if enabled
      if (playNextSongAutomatically.value) {
        print('[AudioHandler] Auto-play next song');
        await _handleAutoPlayNext();
      } else {
        print('[AudioHandler] No next song available');
      }
    } catch (e, stackTrace) {
      logger.log('Error skipping to next song', e, stackTrace);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    try {
      print(
          '[AudioHandler] skipToPrevious called. Current index: $_currentQueueIndex');

      if (repeatNotifier.value == AudioServiceRepeatMode.one) {
        print('[AudioHandler] Repeat one mode, playing again');
        await playAgain();
        return;
      }

      // If there's a previous song in queue, play it
      if (_currentQueueIndex > 0) {
        print('[AudioHandler] Playing previous song in queue');
        await _playFromQueue(_currentQueueIndex - 1);
        return;
      }

      // If repeat all is enabled and we have songs in queue
      if (repeatNotifier.value == AudioServiceRepeatMode.all &&
          _queueList.isNotEmpty) {
        print('[AudioHandler] Repeat all mode, playing last song');
        await _playFromQueue(_queueList.length - 1);
        return;
      }

      // Play from history if available
      if (_historyList.isNotEmpty) {
        print('[AudioHandler] Playing from history');
        final previousSong = _historyList.removeAt(0);
        _queueList.insert(0, previousSong);
        _currentQueueIndex = 0;
        await _playFromQueue(0);
      } else {
        print('[AudioHandler] No previous song available');
      }
    } catch (e, stackTrace) {
      logger.log('Error skipping to previous song', e, stackTrace);
    }
  }

  Future<void> playAgain() async {
    try {
      await audioPlayer.seek(Duration.zero);
    } catch (e, stackTrace) {
      logger.log('Error playing again', e, stackTrace);
    }
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode shuffleMode) async {
    try {
      final shuffleEnabled = shuffleMode != AudioServiceShuffleMode.none;
      shuffleNotifier.value = shuffleEnabled;
      await audioPlayer.setShuffleModeEnabled(shuffleEnabled);
    } catch (e, stackTrace) {
      logger.log('Error setting shuffle mode', e, stackTrace);
    }
  }

  @override
  Future<void> setRepeatMode(AudioServiceRepeatMode repeatMode) async {
    try {
      repeatNotifier.value = repeatMode;
      switch (repeatMode) {
        case AudioServiceRepeatMode.none:
          await audioPlayer.setLoopMode(LoopMode.off);
          break;
        case AudioServiceRepeatMode.one:
          await audioPlayer.setLoopMode(LoopMode.one);
          break;
        case AudioServiceRepeatMode.all:
        case AudioServiceRepeatMode.group:
          await audioPlayer.setLoopMode(LoopMode.all);
          break;
      }
    } catch (e, stackTrace) {
      logger.log('Error setting repeat mode', e, stackTrace);
    }
  }

  Future<void> setSleepTimer(Duration duration) async {
    try {
      _sleepTimer?.cancel();
      sleepTimerExpired = false;
      sleepTimerNotifier.value = duration;

      _sleepTimer = Timer(duration, () async {
        sleepTimerExpired = true;
        await pause();
        sleepTimerNotifier.value = Duration.zero;
      });
    } catch (e, stackTrace) {
      logger.log('Error setting sleep timer', e, stackTrace);
    }
  }

  void cancelSleepTimer() {
    try {
      _sleepTimer?.cancel();
      _sleepTimer = null;
      sleepTimerExpired = false;
      sleepTimerNotifier.value = Duration.zero;
    } catch (e, stackTrace) {
      logger.log('Error canceling sleep timer', e, stackTrace);
    }
  }

  void changeSponsorBlockStatus() {
    sponsorBlockSupport.value = !sponsorBlockSupport.value;
    addOrUpdateData(
      'settings',
      'sponsorBlockSupport',
      sponsorBlockSupport.value,
    );
  }

  void changeAutoPlayNextStatus() {
    playNextSongAutomatically.value = !playNextSongAutomatically.value;
    addOrUpdateData(
      'settings',
      'playNextSongAutomatically',
      playNextSongAutomatically.value,
    );
  }

  @override
  Future<void> customAction(String name, [Map<String, dynamic>? extras]) async {
    try {
      switch (name) {
        case 'clearQueue':
          clearQueue();
          break;
        case 'addToQueue':
          if (extras?['song'] != null) {
            await addToQueue(
              extras!['song'] as Map,
              playNext: extras['playNext'] ?? false,
            );
          }
          break;
        case 'removeFromQueue':
          if (extras?['index'] != null) {
            await removeFromQueue(extras!['index'] as int);
          }
          break;
        case 'reorderQueue':
          if (extras?['oldIndex'] != null && extras?['newIndex'] != null) {
            await reorderQueue(
              extras!['oldIndex'] as int,
              extras['newIndex'] as int,
            );
          }
          break;
        default:
          await super.customAction(name, extras);
      }
    } catch (e, stackTrace) {
      logger.log('Error in customAction: $name', e, stackTrace);
    }
  }
}
