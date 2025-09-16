import 'package:flutter/material.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/models/position_data.dart';
import 'package:j3tunes/utilities/formatter.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class PositionSlider extends StatefulWidget {
  const PositionSlider({
    super.key,
    this.youtubeController,
    this.isVideoMode = false,
  });

  final YoutubePlayerController? youtubeController;
  final bool isVideoMode;

  @override
  State<PositionSlider> createState() => _PositionSliderState();
}

class _PositionSliderState extends State<PositionSlider> {
  bool _isDragging = false;
  double _dragValue = 0;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: widget.isVideoMode && widget.youtubeController != null
          ? _buildVideoSlider()
          : _buildAudioSlider(),
    );
  }

  Widget _buildVideoSlider() {
    return ValueListenableBuilder<YoutubePlayerValue>(
      valueListenable: widget.youtubeController!,
      builder: (context, value, child) {
        final position = value.position;
        final duration = value.metaData.duration;
        final maxDuration =
            duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
        final currentValue =
            _isDragging ? _dragValue : position.inSeconds.toDouble();

        return _buildSliderWidget(
          currentValue,
          maxDuration,
          position,
          duration,
          onChanged: (val) {
            setState(() {
              _isDragging = true;
              _dragValue = val;
            });
          },
          onChangeEnd: (val) {
            widget.youtubeController!.seekTo(Duration(seconds: val.toInt()));
            setState(() {
              _isDragging = false;
            });
          },
        );
      },
    );
  }

  Widget _buildAudioSlider() {
    return StreamBuilder<PositionData>(
      stream: audioHandler.positionDataStream.distinct(),
      builder: (context, snapshot) {
        final hasData = snapshot.hasData && snapshot.data != null;
        final positionData = hasData
            ? snapshot.data!
            : PositionData(Duration.zero, Duration.zero, Duration.zero);

        final maxDuration = positionData.duration.inSeconds > 0
            ? positionData.duration.inSeconds.toDouble()
            : 1.0;
        final currentValue = _isDragging
            ? _dragValue
            : positionData.position.inSeconds.toDouble();

        return _buildSliderWidget(
          currentValue,
          maxDuration,
          positionData.position,
          positionData.duration,
          onChanged: hasData
              ? (value) {
                  setState(() {
                    _isDragging = true;
                    _dragValue = value;
                  });
                }
              : null,
          onChangeEnd: hasData
              ? (value) {
                  audioHandler.seek(Duration(seconds: value.toInt()));
                  setState(() {
                    _isDragging = false;
                  });
                }
              : null,
        );
      },
    );
  }

  Widget _buildSliderWidget(
    double currentValue,
    double maxDuration,
    Duration position,
    Duration duration, {
    ValueChanged<double>? onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Video control buttons above slider (only show in video mode)
        if (widget.isVideoMode && widget.youtubeController != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Speed control button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: PopupMenuButton<double>(
                    icon: Icon(
                      Icons.speed,
                      color: Colors.white,
                      size: 18,
                    ),
                    color: Colors.black.withOpacity(0.8),
                    onSelected: (speed) {
                      widget.youtubeController!.setPlaybackRate(speed);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 0.5,
                          child: Text('0.5x',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 0.75,
                          child: Text('0.75x',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 1.0,
                          child: Text('1x',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 1.25,
                          child: Text('1.25x',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 1.5,
                          child: Text('1.5x',
                              style: TextStyle(color: Colors.white))),
                      PopupMenuItem(
                          value: 2.0,
                          child: Text('2x',
                              style: TextStyle(color: Colors.white))),
                    ],
                  ),
                ),
                // Full screen button,
                Row(
                  children: [

              
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.fullscreen,
                      color: Colors.white,
                      size: 18,
                    ),
                    onPressed: () {
                      widget.youtubeController!.toggleFullScreenMode();
                    },
                    padding: EdgeInsets.all(6),
                    constraints: BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
                
                ]),
              ],
            ),
          ),

        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white.withOpacity(0.3),
            thumbColor: Colors.white,
            overlayColor: Colors.white.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            trackHeight: 3,
          ),
          child: Slider(
            value: currentValue.clamp(0.0, maxDuration),
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
            max: maxDuration,
          ),
        ),
        _buildPositionRow(context, position, duration),
      ],
    );
  }

  Widget _buildPositionRow(
    BuildContext context,
    Duration position,
    Duration duration,
  ) {
    final positionText = formatDuration(position.inSeconds);
    final durationText = formatDuration(duration.inSeconds);

    final textStyle = TextStyle(
      fontSize: 15,
      color: Colors.white.withOpacity(0.8),
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(positionText, style: textStyle),
          Text(durationText, style: textStyle),
        ],
      ),
    );
  }
}