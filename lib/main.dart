// ignore_for_file: unused_field, unused_import

import 'dart:async';
import 'dart:io';

// The window_manager package is required for setting the window size.
// Add `window_manager: ^0.3.8` to your pubspec.yaml
import 'package:home_widget/home_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:j3tunes/firebase_options.dart';

import 'package:j3tunes/API/musify.dart';
import 'package:j3tunes/localization/app_localizations.dart';
import 'package:app_links/app_links.dart';
import 'package:audio_service/audio_service.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/services/audio_service.dart';
import 'package:j3tunes/services/data_manager.dart' hide addOrUpdateData;
import 'package:j3tunes/services/io_service.dart';
import 'package:j3tunes/services/logger_service.dart';
import 'package:j3tunes/services/playlist_sharing.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/services/update_manager.dart';
import 'package:j3tunes/widgets/MusicWidgetProvider.dart';
import 'package:j3tunes/style/app_themes.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:j3tunes/screens/adaptive_layout.dart';
import 'package:j3tunes/screens/mobile_ui/bottom_navigation_page.dart';
import 'package:j3tunes/screens/desktop_ui/desktop_scaffold.dart';
import 'package:window_manager/window_manager.dart';

/// Global notifier for the currently selected song (for instant SongBar update)
final ValueNotifier<Map<String, dynamic>?> currentSongNotifier = ValueNotifier<Map<String, dynamic>?>(null);

late J3TunesAudioHandler audioHandler;

final logger = Logger();
final appLinks = AppLinks();

bool isFdroidBuild = false;
bool isUpdateChecked = false;

const appLanguages = <String, String>{
  'English': 'en',
  'Arabic': 'ar',
  'Chinese (Simplified)': 'zh',
  'Chinese (Traditional)': 'zh-Hant',
  'French': 'fr',
  'German': 'de',
  'Greek': 'el',
  'Hindi': 'hi',
  'Hebrew': 'he',
  'Indonesian': 'id',
  'Italian': 'it',
  'Japanese': 'ja',
  'Korean': 'ko',
  'Russian': 'ru',
  'Polish': 'pl',
  'Portuguese': 'pt',
  'Spanish': 'es',
  'Swedish': 'sv',
  'Turkish': 'tr',
  'Ukrainian': 'uk',
};

final List<Locale> appSupportedLocales =
    appLanguages.values.map((languageCode) {
  final parts = languageCode.split('-');
  if (parts.length > 1) {
    return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
  }
  return Locale(languageCode);
}).toList();

class J3Tunes extends StatefulWidget {
  const J3Tunes({super.key});

  static Future<void> updateAppState(
    BuildContext context, {
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? useSystemColor,
  }) async {
    context.findAncestorStateOfType<_J3TunesState>()!.changeSettings(
          newThemeMode: newThemeMode,
          newLocale: newLocale,
          newAccentColor: newAccentColor,
          systemColorStatus: useSystemColor,
        );
  }

  @override
  _J3TunesState createState() => _J3TunesState();
}

class _J3TunesState extends State<J3Tunes> with WidgetsBindingObserver {
  void changeSettings({
    ThemeMode? newThemeMode,
    Locale? newLocale,
    Color? newAccentColor,
    bool? systemColorStatus,
  }) {
    setState(() {
      if (newThemeMode != null) {
        themeMode = newThemeMode;
        brightness = getBrightnessFromThemeMode(newThemeMode);
      }
      if (newLocale != null) {
        languageSetting = newLocale;
      }
      if (newAccentColor != null) {
        if (systemColorStatus != null &&
            useSystemColor.value != systemColorStatus) {
          useSystemColor.value = systemColorStatus;
          addOrUpdateData('settings', 'useSystemColor', systemColorStatus);
        }
        primaryColorSetting = newAccentColor;
      }
    });
  }

  AppLifecycleState? _lastLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    final platformDispatcher = PlatformDispatcher.instance;

    // This callback is called every time the brightness changes.
    platformDispatcher.onPlatformBrightnessChanged = () {
      if (themeMode == ThemeMode.system) {
        setState(() {
          brightness = platformDispatcher.platformBrightness;
        });
      }
    };

    try {
      LicenseRegistry.addLicense(() async* {
        final license = await rootBundle.loadString(
          'assets/licenses/paytone.txt',
        );
        yield LicenseEntryWithLineBreaks(['paytoneOne'], license);
      });
    } catch (e, stackTrace) {
      logger.log('License Registration Error', e, stackTrace);
    }

    if (!isFdroidBuild &&
        !isUpdateChecked &&
        !offlineMode.value &&
        kReleaseMode) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        checkAppUpdates();
        isUpdateChecked = true;
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    Hive.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes, always go to splash screen to re-check auth state and handle navigation.
    if (state == AppLifecycleState.resumed && _lastLifecycleState == AppLifecycleState.paused) {
      NavigationManager.router.go('/splash');
    }

    // Refresh audio handler state when app resumes to ensure UI updates
    if (state == AppLifecycleState.resumed) {
      audioHandler.customAction('refreshState');
    }
    _lastLifecycleState = state;
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (lightColorScheme, darkColorScheme) {
        final colorScheme = getAppColorScheme(
          lightColorScheme,
          darkColorScheme,
        );

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: true,
            statusBarBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            statusBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
            systemNavigationBarIconBrightness: brightness == Brightness.dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: MaterialApp.router(
            debugShowCheckedModeBanner: false,
            themeMode: themeMode,
            darkTheme: getAppTheme(colorScheme),
            theme: getAppTheme(colorScheme),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: appSupportedLocales,
            locale: languageSetting,
            routerConfig: NavigationManager.router,
          ),
        );
      },
    );
  }
}

// Must be a top-level function
@pragma('vm:entry-point')
void backgroundCallback(Uri? uri) async {
  // This function is called when the widget is clicked, but we are using
  // standard MediaButtonReceiver intents on the native side for controls,
  // so this callback is mainly for other potential interactions.
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!isFdroidBuild) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // FirebaseAuth.instance.useAuthEmulator('localhost', 9099); // Comment out if not using emulator
  }
  
  // Initialize Hive and other services first
  await initialisation();

  // Add these error handlers before runApp
  FlutterError.onError = (FlutterErrorDetails details) {
    logger.log('Flutter Error', details.exception, details.stack);
  };

  // Set minimum window size for desktop platforms.
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();

    // Set the window icon for Windows. This is not supported on macOS.
    if (Platform.isWindows) {
      // Make sure to add an icon file (e.g., 'assets/app_icon.ico') to your project's assets.
      await windowManager.setIcon('assets/app_icon.ico');
    }

    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      minimumSize: Size(375, 700), // Enforce minimum size
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  PlatformDispatcher.instance.onError = (error, stack) {
    logger.log('Platform Error', error, stack);
    return true;
  };

  runApp(const J3Tunes());
}

Future<void> initialisation() async {
  try {
    await Hive.initFlutter();

    await Future.wait([
      Hive.openBox('settings'),
      Hive.openBox('user'),
      Hive.openBox('userNoBackup'),
      Hive.openBox('cache'),
    ]);

    audioHandler = await AudioService.init(
      builder: J3TunesAudioHandler.new,
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.jatin.J3Tunes',
        androidNotificationChannelName: 'J3Tunes',
        androidNotificationIcon: 'drawable/ic_launcher_foreground',
        androidShowNotificationBadge: true,
        androidStopForegroundOnPause: false,
      ),
    );

    // Initialize our new widget service
    // MusicWidgetService().init(); // Commented out as MusicWidgetExtension is not used for iOS

    // Init router
    NavigationManager.instance;

    try {
      // Listen to incoming links while app is running
      appLinks.uriLinkStream.listen(
        handleIncomingLink,
        onError: (err) {
          logger.log('URI link error:', err, null);
        },
      );
    } on PlatformException {
      logger.log('Failed to get initial uri', null, null);
    }
  } catch (e, stackTrace) {
    logger.log('Initialization Error', e, stackTrace);
  }

  applicationDirPath = (await getApplicationDocumentsDirectory()).path;
  await FilePaths.ensureDirectoriesExist();
}
Future<void> _handleFirstRun() async {
  final prefs = await SharedPreferences.getInstance();
  final bool hasRunBefore = prefs.getBool('hasRunBefore') ?? false;

  if (!hasRunBefore) {
    // This is the first run after install/reinstall.
    // Sign out any lingering user to ensure a fresh start.
    await FirebaseAuth.instance.signOut();
    await prefs.setBool('hasRunBefore', true);
  }
}

void handleIncomingLink(Uri? uri) async {
  if (uri != null && uri.scheme == 'J3Tunes' && uri.host == 'playlist') {
    try {
      if (uri.pathSegments[0] == 'custom') {
        final encodedPlaylist = uri.pathSegments[1];

        final playlist = await PlaylistSharingService.decodeAndExpandPlaylist(
          encodedPlaylist,
        );

        if (playlist != null) {
          userCustomPlaylists.value = [...userCustomPlaylists.value, playlist];
          await addOrUpdateData(
            'user',
            'customPlaylists',
            userCustomPlaylists.value,
          );
          showToast(
            NavigationManager().context,
            '${NavigationManager().context.l10n!.addedSuccess}!',
          );
        } else {
          showToast(NavigationManager().context, 'Invalid playlist data');
        }
      }
    } catch (e) {
      showToast(NavigationManager().context, 'Failed to load playlist');
    }
  }
}
