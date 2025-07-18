import 'package:flutter/material.dart';

class MusicWidgetProvider extends StatelessWidget {
  const MusicWidgetProvider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Placeholder widget, replace with your actual widget implementation
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.black,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('No Song', style: TextStyle(color: Colors.white, fontSize: 18)),
          Text('Unknown Artist', style: TextStyle(color: Colors.white70)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.skip_previous, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.play_arrow, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.skip_next, color: Colors.white),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}
