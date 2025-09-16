import 'dart:ui';

import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/widgets/song_bar.dart';

class QueueSheet extends StatefulWidget {
  const QueueSheet({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<QueueSheet> createState() => _QueueSheetState();
}

class _QueueSheetState extends State<QueueSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrent();
    });
  }

  void _scrollToCurrent() {
    final currentIndex = audioHandler.currentQueueIndex;
    if (currentIndex != null &&
        currentIndex > 0 &&
        widget.scrollController.hasClients) {
      // Estimate item height. A more complex solution would use GlobalKeys,
      // but an estimation is simpler and often sufficient for this UI.
      // SongBar Padding(v:2*2) + Card Margin(b:3) + Card Padding(v:8*2) + Artwork(55) = 78
      const itemHeight = 78.0;
      final maxScroll = widget.scrollController.position.maxScrollExtent;
      final offset = (currentIndex * itemHeight).clamp(0.0, maxScroll);

      widget.scrollController.animateTo(
        offset,
        duration: const Duration(milliseconds: 800),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final queue = audioHandler.currentQueue;
    final currentIndex = audioHandler.currentQueueIndex;
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.colorScheme.surface.withOpacity(0.9),
            Colors.black.withOpacity(0.95),
          ],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Column(
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            // Title
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(16.0, 0, 16.0, 8.0),
              child: Text(
                context.l10n!.playlist,
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(
              color: Colors.white24,
              indent: 16,
              endIndent: 16,
              height: 1,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Drag handle to reorder, swipe left to remove',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withOpacity(0.7),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            // The list
            Expanded(
              child: queue.isEmpty
                  ? Center(
                      child: Text(
                        context.l10n!.noSongsInQueue,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
                      scrollController: widget.scrollController,
                      itemCount: queue.length,
                      proxyDecorator:
                          (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: Colors.transparent,
                          elevation: 4.0,
                          child: ScaleTransition(
                            scale: animation
                                .drive(Tween<double>(begin: 1.0, end: 1.05)),
                            child: child,
                          ),
                        );
                      },
                      onReorder: (int oldIndex, int newIndex) {
                        setState(() {
                          if (oldIndex < newIndex) {
                            newIndex -= 1;
                          }
                          audioHandler.customAction('reorderQueue',
                              {'oldIndex': oldIndex, 'newIndex': newIndex});
                        });
                      },
                      itemBuilder: (context, index) {
                        final song = queue[index];
                        final isCurrent = index == currentIndex;

                        return Dismissible(
                          key: ValueKey(song['ytid']),
                          direction: DismissDirection.endToStart,
                          onDismissed: (direction) {
                            setState(() {
                              audioHandler.customAction('removeFromQueue', {'index': index});
                            });
                          },
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: const [
                                Text(
                                  'Remove',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Icon(FluentIcons.delete_24_filled, color: Colors.white),
                              ],
                            ),
                          ),
                          child: SongBar(
                              song,
                              false, // clearPlaylist is false
                              onPlay: () => audioHandler.skipToQueueItem(index),
                              backgroundColor: isCurrent
                                  ? theme.colorScheme.primary.withOpacity(0.25)
                                  : Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                              leading: ReorderableDragStartListener(
                                index: index,
                                child: const Padding(
                                  padding: EdgeInsets.only(right: 8.0),
                                  child: Icon(FluentIcons.re_order_dots_vertical_24_regular, color: Colors.white70),
                                ),
                              ),
                            ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}