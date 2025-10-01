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

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:j3tunes/API/version.dart';
import 'package:j3tunes/screens/auth/login_page.dart';
import 'package:j3tunes/screens/auth/signup_page.dart';
import 'package:j3tunes/screens/about_page.dart';
import 'package:j3tunes/screens/adaptive_layout.dart';
import 'package:j3tunes/screens/mobile_ui/bottom_navigation_page.dart';
import 'package:j3tunes/screens/home_page.dart';
import 'package:j3tunes/screens/library_page.dart';
import 'package:j3tunes/screens/search_page.dart';
import 'package:j3tunes/screens/settings_page.dart';
import 'package:j3tunes/screens/user_profile_page.dart';
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
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) =>
            getPage(child: const LoginPage(), state: state),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        pageBuilder: (context, state) =>
            getPage(child: const SignUpPage(), state: state),
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
      initialLocation: '/splash',
      routes: routes,
      restorationScopeId: 'router',
      refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
      redirect: (BuildContext context, GoRouterState state) {
        final bool loggedIn = FirebaseAuth.instance.currentUser != null;
        final bool onAuthScreen =
            state.matchedLocation == '/login' || state.matchedLocation == '/signup';
        final bool onSplashScreen = state.matchedLocation == '/splash';

        // Agar splash screen par hai, to use wahi rehne do. Splash screen khud navigation handle karegi.
        if (onSplashScreen) {
          return null;
        }

        // Agar user logged in nahi hai aur auth screen par nahi hai, to login par bhejo.
        if (!loggedIn && !onAuthScreen) {
          return '/login';
        }

        // Agar user logged in hai aur auth screen par hai, to home par bhejo.
        if (loggedIn && onAuthScreen) {
          return '/home';
        }

        // Baaki sab cases mein, koi redirection nahi.
        return null;
      },
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
  static const String profilePath = '/settings/profile';

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
                  applicationName: 'JTunes',
                  // applicationVersion: appVersion,
                ),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const UserProfilePage(),
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
                  applicationName: 'JTunes',
                  // applicationVersion: appVersion,
                ),
              ),
              GoRoute(
                path: 'about',
                builder: (context, state) => const AboutPage(),
              ),
              GoRoute(
                path: 'profile',
                builder: (context, state) => const UserProfilePage(),
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

/// A utility class to convert a [Stream] to a [Listenable] for `GoRouter`.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
