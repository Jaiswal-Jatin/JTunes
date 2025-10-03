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
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({super.key, required this.child});

  final StatefulNavigationShell child;

  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  List<NavigationDestination> _getNavigationDestinations(BuildContext context) {
    return !offlineMode.value
        ? [
            NavigationDestination(
              icon: const Icon(FluentIcons.home_24_regular),
              selectedIcon: const Icon(FluentIcons.home_24_filled),
              label: context.l10n?.home ?? 'Home',
            ),
            NavigationDestination(
              icon: const Icon(FluentIcons.search_24_regular),
              selectedIcon: const Icon(FluentIcons.search_24_filled),
              label: context.l10n?.search ?? 'Search',
            ),
            NavigationDestination(
              icon: const Icon(FluentIcons.book_24_regular),
              selectedIcon: const Icon(FluentIcons.book_24_filled),
              label: context.l10n?.library ?? 'Library',
            ),
            NavigationDestination(
              icon: const Icon(FluentIcons.settings_24_regular),
              selectedIcon: const Icon(FluentIcons.settings_24_filled),
              label: context.l10n?.settings ?? 'Settings',
            ),
          ]
        : [
            NavigationDestination(
              icon: const Icon(FluentIcons.home_24_regular),
              selectedIcon: const Icon(FluentIcons.home_24_filled),
              label: context.l10n?.home ?? 'Home',
            ),
            NavigationDestination(
              icon: const Icon(FluentIcons.book_24_regular),
              selectedIcon: const Icon(FluentIcons.book_24_filled),
              label: context.l10n?.library ?? 'Library',
            ),
            NavigationDestination(
              icon: const Icon(FluentIcons.settings_24_regular),
              selectedIcon: const Icon(FluentIcons.settings_24_filled),
              label: context.l10n?.settings ?? 'Settings',
            ),
          ];
  }

  bool _isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width >= 600;
  }

  // Define a GlobalKey for the search page state
  final GlobalKey searchPageKey = GlobalKey();

  void onTabSelected(int index) {
    if (index == 1) {
      // search tab ka index
      // Force refresh search screen
      NavigationManager.router.go('/search');
      // Clear search results if search screen has state
      if (searchPageKey.currentState != null) {
        (searchPageKey.currentState as dynamic).clearSearchResults();
      }
    }
  }

  void _handleTabTap(int index) {
    final currentIndex = widget.child.currentIndex;
    final isActive = index == currentIndex;

    // Map bottom nav index to the corresponding navigator key
    GlobalKey<NavigatorState>? branchKey;
    if (!offlineMode.value) {
      switch (index) {
        case 0:
          branchKey = NavigationManager.homeTabNavigatorKey;
          break;
        case 1:
          branchKey = NavigationManager.searchTabNavigatorKey;
          break;
        case 2:
          branchKey = NavigationManager.libraryTabNavigatorKey;
          break;
        case 3:
          branchKey = NavigationManager.settingsTabNavigatorKey;
          break;
      }
    } else {
      // Offline mode has fewer tabs (Home, Library, Settings)
      switch (index) {
        case 0:
          branchKey = NavigationManager.homeTabNavigatorKey;
          break;
        case 1:
          branchKey = NavigationManager.libraryTabNavigatorKey;
          break;
        case 2:
          branchKey = NavigationManager.settingsTabNavigatorKey;
          break;
      }
    }

    if (isActive) {
      // If user tapped the already active tab, pop that tab's navigator to its first route
      try {
        branchKey?.currentState?.popUntil((route) => route.isFirst);
      } catch (_) {
        // ignore - navigator might not be ready
      }

      // Special-case search tab: refresh/clear results when re-tapping
      if (!offlineMode.value && index == 1) {
        NavigationManager.router.go('/search');
        if (searchPageKey.currentState != null) {
          (searchPageKey.currentState as dynamic).clearSearchResults();
        }
      }
    }

    // Finally, tell the shell to go to the branch. Keep initialLocation true when re-tapping.
    widget.child.goBranch(
      index,
      initialLocation: isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = _isLargeScreen(context);

        return Scaffold(
          body: Row(
            children: [
              if (isLargeScreen)
                NavigationRail(
                  labelType: NavigationRailLabelType.selected,
                  destinations: _getNavigationDestinations(context)
                      .map(
                        (destination) => NavigationRailDestination(
                          icon: destination.icon,
                          selectedIcon: destination.selectedIcon,
                          label: Text(destination.label),
                        ),
                      )
                      .toList(),
                  selectedIndex: widget.child.currentIndex,
                  onDestinationSelected: (index) {
                    _handleTabTap(index);
                  },
                ),
              Expanded(
                child: Stack(
                  children: [
                    widget.child,
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: StreamBuilder<MediaItem?>(
                        stream: audioHandler.mediaItem.distinct((prev, curr) {
                          if (prev == null || curr == null) return false;
                          return prev.id == curr.id &&
                              prev.title == curr.title &&
                              prev.artist == curr.artist &&
                              prev.artUri == curr.artUri;
                        }),
                        builder: (context, snapshot) {
                          final metadata = snapshot.data;
                          if (metadata == null) {
                            return const SizedBox.shrink();
                          }
                          return MiniPlayer();
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          bottomNavigationBar: !isLargeScreen
              ? NavigationBar(
                  selectedIndex: widget.child.currentIndex,
                  height: 60,
                  labelBehavior: languageSetting == const Locale('en', '')
                      ? NavigationDestinationLabelBehavior.onlyShowSelected
                      : NavigationDestinationLabelBehavior.alwaysHide,
                  onDestinationSelected: (index) {
                    _handleTabTap(index);
                  },
                  destinations: _getNavigationDestinations(context),
                )
              : null,
        );
      },
    );
  }
}
