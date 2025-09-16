import 'package:flutter/material.dart';
import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/song_bar.dart';

class QueueListView extends StatelessWidget {
  const QueueListView({super.key});

  @override
  Widget build(BuildContext context) {
    final _textColor = Colors.white.withOpacity(0.9);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            context.l10n!.playlist,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(
                  color: _textColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Expanded(
          child: activePlaylist['list'].isEmpty
              ? Center(
                  child: Text(
                    context.l10n!.noSongsInQueue,
                    style: TextStyle(color: _textColor),
                  ),
                )
              : ListView.builder(
                  itemCount: activePlaylist['list'].length,
                  itemBuilder: (context, index) {
                    final borderRadius = getItemBorderRadius(
                      index,
                      activePlaylist['list'].length,
                    );
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: borderRadius,
                      ),
                      child: SongBar(
                        activePlaylist['list'][index],
                        false,
                        onPlay: () {
                          audioHandler.playPlaylistSong(songIndex: index);
                        },
                        backgroundColor: Colors.transparent,
                        borderRadius: borderRadius,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}