// ignore_for_file: prefer_const_constructors

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

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:j3tunes/API/version.dart';
import 'package:j3tunes/screens/about_page.dart';
import 'package:j3tunes/screens/adaptive_layout.dart';
import 'package:j3tunes/screens/mobile_ui/bottom_navigation_page.dart';
import 'package:j3tunes/screens/home_page.dart';
import 'package:j3tunes/screens/library_page.dart';
import 'package:j3tunes/screens/search_page.dart';
import 'package:j3tunes/screens/settings_page.dart';
import 'package:j3tunes/screens/user_songs_page.dart';
import 'package:j3tunes/screens/splash_screen.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_scaffold.dart';
import 'package:j3tunes/services/settings_manager.dart';

class NavigationManager {
  factory NavigationManager() {
    return _instance;
  }

  NavigationManager._internal() {
    _setupRouter();
  }

  void _setupRouter() {
    final routes = [
      // Splash Screen Route - First route
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) {
          return getPage(child: const SplashScreen(), state: state);
        },
      ),
      
      // Main App Routes
      StatefulShellRoute.indexedStack(
        parentNavigatorKey: parentNavigatorKey,
        builder: (context, state, navigationShell) {
          return AdaptiveLayout(
            mobileLayout: (context) =>
                BottomNavigationPage(child: navigationShell),
            desktopLayout: (context) =>
                DesktopScaffold(child: navigationShell),
          );
        },
        branches: !offlineMode.value ? _onlineRoutes() : _offlineRoutes(),
      ),
    ];

    router = GoRouter(
      navigatorKey: parentNavigatorKey,
      initialLocation: '/splash', // Start with splash screen
      routes: routes,
      restorationScopeId: 'router',
      debugLogDiagnostics: kDebugMode,
      routerNeglect: true,
    );
  }

  static final NavigationManager _instance = NavigationManager._internal();

  static NavigationManager get instance => _instance;

  static late final GoRouter router;

  static final GlobalKey<NavigatorState> parentNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> homeTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> searchTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> libraryTabNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> settingsTabNavigatorKey =
      GlobalKey<NavigatorState>();

  BuildContext get context =>
      router.routerDelegate.navigatorKey.currentContext!;

  GoRouterDelegate get routerDelegate => router.routerDelegate;

  GoRouteInformationParser get routeInformationParser =>
      router.routeInformationParser;

  static const String splashPath = '/splash';
  static const String homePath = '/home';
  static const String settingsPath = '/settings';
  static const String searchPath = '/search';
  static const String libraryPath = '/library';

  List<StatefulShellBranch> _onlineRoutes() {
    return [
      StatefulShellBranch(
        navigatorKey: homeTabNavigatorKey,
        routes: [
          GoRoute(
            path: homePath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const HomePage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'library',
                builder: (context, state) => const LibraryPage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: searchTabNavigatorKey,
        routes: [
          GoRoute(
            path: searchPath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const SearchPage(), state: state);
            },
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: libraryTabNavigatorKey,
        routes: [
          GoRoute(
            path: libraryPath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const LibraryPage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'userSongs/:page',
                builder: (context, state) => UserSongsPage(
                  page: state.pathParameters['page'] ?? 'liked',
                ),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: settingsTabNavigatorKey,
        routes: [
          GoRoute(
            path: settingsPath,
            pageBuilder: (context, state) {
              return getPage(child: SettingsPage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'license',
                builder: (context, state) => const LicensePage(
                  applicationName: 'J3Tunes',
                  applicationVersion: appVersion,
                ),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutPage(),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  List<StatefulShellBranch> _offlineRoutes() {
    return [
      StatefulShellBranch(
        navigatorKey: homeTabNavigatorKey,
        routes: [
          GoRoute(
            path: homePath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(
                child: const UserSongsPage(page: 'offline'),
                state: state,
              );
            },
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: libraryTabNavigatorKey,
        routes: [
          GoRoute(
            path: libraryPath,
            pageBuilder: (context, GoRouterState state) {
              return getPage(child: const LibraryPage(), state: state);
            },
          ),
        ],
      ),
      StatefulShellBranch(
        navigatorKey: settingsTabNavigatorKey,
        routes: [
          GoRoute(
            path: settingsPath,
            pageBuilder: (context, state) {
              return getPage(child: SettingsPage(), state: state);
            },
            routes: [
              GoRoute(
                path: 'license',
                builder: (context, state) => const LicensePage(
                  applicationName: 'J3Tunes',
                  applicationVersion: appVersion,
                ),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutPage(),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  static Page getPage({required Widget child, required GoRouterState state}) {
    return MaterialPage(key: state.pageKey, child: child);
  }
}
