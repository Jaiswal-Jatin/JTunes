import 'package:flutter/material.dart';
import 'package:j3tunes/utilities/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_navigation.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_player_bar.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_now_playing_panel.dart';
import 'package:j3tunes/screens/home_page.dart'; // Assuming these are the main content pages
import 'package:j3tunes/screens/library_page.dart';
import 'package:j3tunes/screens/search_page.dart';
import 'package:j3tunes/screens/playlist_page.dart';

/// A scaffold widget for desktop and tablet layouts, providing a consistent
/// structure with a sidebar, main content area, now playing panel, and mini-player.
class DesktopScaffold extends StatelessWidget {
  const DesktopScaffold({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final navigationShell = child as StatefulNavigationShell;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // Left Sidebar Navigation
                DesktopNavigation(
                  selectedIndex: navigationShell.currentIndex,
                  onDestinationSelected: (index) {
                    navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex,
                    );
                  },
                ),
                const VerticalDivider(width: 1),
                // Main Content Area
                Expanded(
                  child: Stack(
                    children: [
                      child,
                      // Bottom Mini-Player (visible on desktop/tablet)
                      const Align(
                        alignment: Alignment.bottomCenter,
                        child: DesktopPlayerBar(),
                      ),
                    ],
                  ),
                ),
                if (isDesktop) ...[
                  const VerticalDivider(width: 1),
                  // Right "Now Playing" Panel (only on wider desktop screens)
                  const SizedBox(
                    width: 300, // Example fixed width for the now playing panel
                    child: DesktopNowPlayingPanel(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
