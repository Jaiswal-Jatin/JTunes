import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/equalizer_sheet.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/mediaitem.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/song_bar.dart';

class BottomActionsRow extends StatelessWidget {
  const BottomActionsRow({
    super.key,
    required this.context,
    required this.audioId,
    required this.metadata,
    required this.iconSize,
    required this.isLargeScreen,
    required this.onQueueButtonPressed,
  });

  final BuildContext context;
  final dynamic audioId;
  final MediaItem metadata;
  final double iconSize;
  final bool isLargeScreen;
  final VoidCallback onQueueButtonPressed;

  @override
  Widget build(BuildContext context) {
    final songLikeStatus = ValueNotifier<bool>(isSongAlreadyLiked(audioId));
    final songOfflineStatus =
        ValueNotifier<bool>(isSongAlreadyOffline(audioId));

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 5,
      runSpacing: 12,
      children: [
        if (!offlineMode.value) _buildLikeButton(songLikeStatus),
        if (!offlineMode.value) _buildAddToPlaylistButton(),
        if (!offlineMode.value) _buildStartRadioButton(),
        StreamBuilder<List<MediaItem>>(
          stream: audioHandler.queue,
          builder: (context, snapshot) {
            if (!isLargeScreen && (snapshot.data?.isNotEmpty ?? false)) {
              return _buildQueueButton(context);
            }
            return const SizedBox.shrink();
          },
        ),
        _buildOfflineButton(songOfflineStatus),
        if (!offlineMode.value) _buildSleepTimerButton(context),
        _buildEqualizerButton(context),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? iconColor,
    bool isActive = false,
    double? size,
  }) {
    final _primaryColor = iconColor ?? Colors.white;
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size ?? iconSize + 28,
        height: size ?? iconSize + 28,
        decoration: BoxDecoration(
          color:
              isActive ? _primaryColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
        ),
        child: IconButton(
          icon: Icon(icon, color: _primaryColor),
          iconSize: iconSize,
          onPressed: onPressed,
          splashRadius: (size ?? iconSize + 28) / 2,
        ),
      ),
    );
  }

  Widget _buildOfflineButton(ValueNotifier<bool> status) {
    return ValueListenableBuilder<bool>(
      valueListenable: status,
      builder: (_, value, __) {
        return _buildActionButton(
          context: context,
          icon: value
              ? FluentIcons.checkmark_circle_24_filled
              : FluentIcons.arrow_download_24_filled,
          tooltip: value ? context.l10n!.removeOffline : context.l10n!.download,
          isActive: value,
          onPressed: () {
            if (value) {
              removeSongFromOffline(audioId);
            } else {
              makeSongOffline(mediaItemToMap(metadata));
            }
            status.value = !status.value;
          },
        );
      },
    );
  }

  Widget _buildAddToPlaylistButton() {
    return _buildActionButton(
      context: context,
      icon: Icons.add,
      tooltip: context.l10n!.addToPlaylist,
      onPressed: () {
        showAddToPlaylistDialog(context, mediaItemToMap(metadata));
      },
    );
  }

  Widget _buildStartRadioButton() {
    return _buildActionButton(
      context: context,
      icon: FluentIcons.music_note_2_24_filled,
      tooltip: 'Start Radio',
      onPressed: () {
        audioHandler.customAction(
          'startRadio',
          {'song': mediaItemToMap(metadata)},
        );
        showToast(context, 'Starting Radio...');
      },
    );
  }

  Widget _buildQueueButton(BuildContext context) {
    return _buildActionButton(
      context: context,
      icon: FluentIcons.apps_list_24_filled,
      tooltip: context.l10n!.playlist,
      onPressed: onQueueButtonPressed,
    );
  }

  Widget _buildEqualizerButton(BuildContext context) {
    return _buildActionButton(
      context: context,
      icon: FluentIcons.options_24_filled,
      tooltip: 'Equalizer',
      onPressed: () => showEqualizerSheet(context),
    );
  }

  Widget _buildSleepTimerButton(BuildContext context) {
    return ValueListenableBuilder<Duration?>(
      valueListenable: sleepTimerNotifier,
      builder: (_, value, __) {
        final isActive = value != null;
        return _buildActionButton(
          context: context,
          icon: isActive
              ? FluentIcons.timer_24_filled
              : FluentIcons.timer_24_regular,
          tooltip:
              isActive ? context.l10n!.sleepTimerCancelled : context.l10n!.setSleepTimer,
          isActive: isActive,
          onPressed: () {
            if (isActive) {
              audioHandler.cancelSleepTimer();
              sleepTimerNotifier.value = null;
              showToast(
                context,
                context.l10n!.sleepTimerCancelled,
                duration: const Duration(seconds: 1, milliseconds: 500),
              );
            } else {
              _showSleepTimerDialog(context);
            }
          },
        );
      },
    );
  }

  Widget _buildLikeButton(ValueNotifier<bool> status) {
    return ValueListenableBuilder<bool>(
      valueListenable: status,
      builder: (_, value, __) {
        return _buildActionButton(
          context: context,
          icon: value ? FluentIcons.heart_24_filled : FluentIcons.heart_24_regular,
          tooltip: value
              ? context.l10n!.removeFromLikedSongs
              : context.l10n!.addToLikedSongs,
          isActive: value,
          onPressed: () {
            updateSongLikeStatus(audioId, !value);
            status.value = !value;
          },
        );
      },
    );
  }

  void _showSleepTimerDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final duration = sleepTimerNotifier.value ?? Duration.zero;
        var hours = duration.inMinutes ~/ 60;
        var minutes = duration.inMinutes % 60;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Colors.black.withOpacity(0.8),
              title: Text(
                context.l10n!.setSleepTimer,
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n!.selectDuration,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n!.hours,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              if (hours > 0) {
                                setState(() {
                                  hours--;
                                });
                              }
                            },
                          ),
                          Text(
                            '$hours',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                hours++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        context.l10n!.minutes,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, color: Colors.white),
                            onPressed: () {
                              if (minutes > 0) {
                                setState(() {
                                  minutes--;
                                });
                              }
                            },
                          ),
                          Text(
                            '$minutes',
                            style: const TextStyle(color: Colors.white),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                minutes++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    context.l10n!.cancel,
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () {
                    final duration = Duration(hours: hours, minutes: minutes);
                    if (duration.inSeconds > 0) {
                      audioHandler.setSleepTimer(duration);
                      showToast(
                        context,
                        context.l10n!.sleepTimerSet,
                        duration: const Duration(seconds: 1, milliseconds: 500),
                      );
                    }
                    Navigator.pop(context);
                  },
                  child: Text(context.l10n!.setTimer),
                ),
              ],
            );
          },
        );
      },
    );
  }
}