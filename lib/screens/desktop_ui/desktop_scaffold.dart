import 'package:flutter/material.dart';
import 'package:j3tunes/utilities/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_navigation.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_player_bar.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_now_playing_panel.dart';

/// A scaffold widget for desktop and tablet layouts, providing a consistent
/// structure with a sidebar, main content area, now playing panel, and mini-player.
class DesktopScaffold extends StatefulWidget {
  const DesktopScaffold({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopScaffold> createState() => _DesktopScaffoldState();
}

class _DesktopScaffoldState extends State<DesktopScaffold> {
  bool _isPanelVisible = true;
  static const double _panelWidth = 300.0;

  void _togglePanel() => setState(() => _isPanelVisible = !_isPanelVisible);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final navigationShell = widget.child as StatefulNavigationShell;

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
                      widget.child,
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
                  // Toggle Button
                  Material(
                    color: Theme.of(context).canvasColor,
                    child: InkWell(
                      onTap: _togglePanel,
                      child: SizedBox(
                        height: double.infinity,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Icon(
                              _isPanelVisible
                                  ? Icons.keyboard_arrow_right
                                  : Icons.keyboard_arrow_left,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Animated "Now Playing" Panel
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    width: _isPanelVisible ? _panelWidth : 0,
                    // Wrap with a horizontal SingleChildScrollView to prevent
                    // overflow errors during the animation.
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: _panelWidth,
                        child: DesktopNowPlayingPanel(),
                      ),
                    ),
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
