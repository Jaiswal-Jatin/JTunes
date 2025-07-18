// ignore_for_file: unused_element, unused_import, directives_ordering

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

import 'package:j3tunes/API/musify.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart';
import 'package:j3tunes/screens/search_page.dart';
import 'package:j3tunes/services/data_manager.dart';
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/services/settings_manager.dart';
import 'package:j3tunes/services/update_manager.dart';
import 'package:j3tunes/style/app_colors.dart';
import 'package:j3tunes/style/app_themes.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/flutter_bottom_sheet.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:j3tunes/utilities/url_launcher.dart';
import 'package:j3tunes/utilities/utils.dart';
import 'package:j3tunes/widgets/bottom_sheet_bar.dart';
import 'package:j3tunes/widgets/confirmation_dialog.dart';
import 'package:j3tunes/widgets/custom_bar.dart';
import 'package:j3tunes/widgets/section_header.dart';

import 'package:j3tunes/widgets/user_profile_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final activatedColor = Theme.of(context).colorScheme.secondaryContainer;
    final inactivatedColor = Theme.of(context).colorScheme.surfaceContainerHigh;

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.settings)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: <Widget>[
            // User Profile Section at the top
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: UserProfileCard(
                showGreeting: false,
                isCompact: false,
              ),
            ),
            _buildPreferencesSection(
              context,
              primaryColor,
              activatedColor,
              inactivatedColor,
            ),
            if (!offlineMode.value)
              _buildOnlineFeaturesSection(
                context,
                activatedColor,
                inactivatedColor,
                primaryColor,
              ),
            _buildOthersSection(context),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(
    BuildContext context,
    Color primaryColor,
    Color activatedColor,
    Color inactivatedColor,
  ) {
    return Column(
      children: [
        SectionHeader(title: context.l10n!.preferences),
        CustomBar(
          context.l10n!.accentColor,
          FluentIcons.color_24_filled,
          borderRadius: commonCustomBarRadiusFirst,
          onTap: () => _showAccentColorPicker(context),
        ),
        CustomBar(
          context.l10n!.themeMode,
          FluentIcons.weather_sunny_28_filled,
          onTap: () => _showThemeModePicker(
            context,
            activatedColor,
            inactivatedColor,
          ),
        ),
        CustomBar(
          context.l10n!.language,
          FluentIcons.translate_24_filled,
          onTap: () => _showLanguagePicker(
            context,
            activatedColor,
            inactivatedColor,
          ),
        ),
        CustomBar(
          context.l10n!.audioQuality,
          Icons.music_note,
          onTap: () => _showAudioQualityPicker(
            context,
            activatedColor,
            inactivatedColor,
          ),
        ),
        // CustomBar(
        //   context.l10n!.dynamicColor,
        //   FluentIcons.toggle_left_24_filled,
        //   trailing: Switch(
        //     value: useSystemColor.value,
        //     onChanged: (value) => _toggleSystemColor(context, value),
        //   ),
        // ),
        if (themeMode == ThemeMode.dark)
          CustomBar(
            context.l10n!.pureBlackTheme,
            FluentIcons.color_background_24_filled,
            trailing: Switch(
              value: usePureBlackColor.value,
              onChanged: (value) => _togglePureBlack(context, value),
            ),
          ),
        // ValueListenableBuilder<bool>(
        //   valueListenable: predictiveBack,
        //   builder: (_, value, __) {
        //     return CustomBar(
        //       context.l10n!.predictiveBack,
        //       FluentIcons.position_backward_24_filled,
        //       trailing: Switch(
        //         value: value,
        //         onChanged: (value) => _togglePredictiveBack(context, value),
        //       ),
        //     );
        //   },
        // ),
        // ValueListenableBuilder<bool>(
        //   valueListenable: offlineMode,
        //   builder: (_, value, __) {
        //     return CustomBar(
        //       context.l10n!.offlineMode,
        //       FluentIcons.cellular_off_24_regular,
        //       trailing: Switch(
        //         value: value,
        //         onChanged: (value) => _toggleOfflineMode(context, value),
        //       ),
        //     );
        //   },
        // ),
        ValueListenableBuilder<bool>(
          valueListenable: backgroundPlay,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.backgroundPlay,
              FluentIcons.dual_screen_tablet_24_filled,
              trailing: Switch(
                value: value,
                onChanged: (value) => _toggleBackgroundPlay(context, value),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildOnlineFeaturesSection(
    BuildContext context,
    Color activatedColor,
    Color inactivatedColor,
    Color primaryColor,
  ) {
    return Column(
      children: [
        // ValueListenableBuilder<bool>(
        //   valueListenable: sponsorBlockSupport,
        //   builder: (_, value, __) {
        //     return CustomBar(
        //       'SponsorBlock',
        //       FluentIcons.presence_blocked_24_regular,
        //       trailing: Switch(
        //         value: value,
        //         onChanged: (value) => _toggleSponsorBlock(context, value),
        //       ),
        //     );
        //   },
        // ),
        ValueListenableBuilder<bool>(
          valueListenable: playNextSongAutomatically,
          builder: (_, value, __) {
            return CustomBar(
              context.l10n!.automaticSongPicker,
              FluentIcons.music_note_2_play_20_filled,
              trailing: Switch(
                value: value,
                onChanged: (value) {
                  audioHandler.changeAutoPlayNextStatus();
                  showToast(context, context.l10n!.settingChangedMsg);
                },
              ),
            );
          },
        ),
        // ValueListenableBuilder<bool>(
        //   valueListenable: defaultRecommendations,
        //   builder: (_, value, __) {
        //     return CustomBar(
        //       context.l10n!.originalRecommendations,
        //       FluentIcons.channel_share_24_regular,
        //       borderRadius: commonCustomBarRadiusLast,
        //       trailing: Switch(
        //         value: value,
        //         onChanged: (value) =>
        //             _toggleDefaultRecommendations(context, value),
        //       ),
        //     );
        //   },
        // ),
        _buildToolsSection(context),
        // _buildSponsorSection(context, primaryColor),
      ],
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: context.l10n!.tools),
        CustomBar(
          context.l10n!.clearCache,
          FluentIcons.broom_24_filled,
          borderRadius: commonCustomBarRadiusFirst,
          onTap: () async {
            final cleared = await clearCache();
            showToast(
              context,
              cleared ? '${context.l10n!.cacheMsg}!' : context.l10n!.error,
            );
          },
        ),
        CustomBar(
          context.l10n!.clearSearchHistory,
          FluentIcons.history_24_filled,
          onTap: () => _showClearSearchHistoryDialog(context),
        ),
        CustomBar(
          context.l10n!.clearRecentlyPlayed,
          FluentIcons.receipt_play_24_filled,
          onTap: () => _showClearRecentlyPlayedDialog(context),
        ),
        CustomBar(
          context.l10n!.backupUserData,
          FluentIcons.cloud_sync_24_filled,
          onTap: () => _backupUserData(context),
        ),
        CustomBar(
          context.l10n!.restoreUserData,
          FluentIcons.cloud_add_24_filled,
          onTap: () async {
            final response = await restoreData(context);
            showToast(context, response);
          },
        ),
        // if (!isFdroidBuild)
        //   CustomBar(
        //     context.l10n!.downloadAppUpdate,
        //     FluentIcons.arrow_download_24_filled,
        //     borderRadius: commonCustomBarRadiusLast,
        //     onTap: checkAppUpdates,
        //   ),
      ],
    );
  }

  // Widget _buildSponsorSection(BuildContext context, Color primaryColor) {
  //   return Column(
  //     children: [
  //       SectionHeader(title: context.l10n!.becomeSponsor),
  //       CustomBar(
  //         context.l10n!.sponsorProject,
  //         FluentIcons.heart_24_filled,
  //         backgroundColor: primaryColor,
  //         iconColor: Colors.white,
  //         textColor: Colors.white,
  //         borderRadius: commonCustomBarRadius,
  //         onTap: () => launchURL(Uri.parse('https://ko-fi.com/gokadzev')),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildOthersSection(BuildContext context) {
    return Column(
      children: [
        SectionHeader(title: context.l10n!.others),
        // CustomBar(
        //   context.l10n!.licenses,
        //   FluentIcons.document_24_filled,
        //   borderRadius: commonCustomBarRadiusFirst,
        //   onTap: () => NavigationManager.router.go('/settings/license'),
        // ),
        // CustomBar(
        //   '${context.l10n!.copyLogs} (${logger.getLogCount()})',
        //   FluentIcons.error_circle_24_filled,
        //   onTap: () async => showToast(context, await logger.copyLogs(context)),
        // ),
        CustomBar(
          context.l10n!.about,
          FluentIcons.book_information_24_filled,
          borderRadius: commonCustomBarRadiusLast,
          onTap: () => NavigationManager.router.go('/settings/about'),
        ),
      ],
    );
  }

  void _showAccentColorPicker(BuildContext context) {
    showCustomBottomSheet(
      context,
      GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
        ),
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        itemCount: availableColors.length,
        itemBuilder: (context, index) {
          final color = availableColors[index];
          final isSelected = color == primaryColorSetting;

          return GestureDetector(
            onTap: () {
              addOrUpdateData(
                'settings',
                'accentColor',
                // ignore: deprecated_member_use
                color.value,
              );
              J3Tunes.updateAppState(
                context,
                newAccentColor: color,
                useSystemColor: false,
              );
              showToast(context, context.l10n!.accentChangeMsg);
              Navigator.pop(context);
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: themeMode == ThemeMode.light
                      ? color.withAlpha(150)
                      : color,
                ),
                if (isSelected)
                  Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showThemeModePicker(
    BuildContext context,
    Color activatedColor,
    Color inactivatedColor,
  ) {
    final availableModes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottmomPadding,
        itemCount: availableModes.length,
        itemBuilder: (context, index) {
          final mode = availableModes[index];
          final borderRadius = getItemBorderRadius(
            index,
            availableModes.length,
          );

          return BottomSheetBar(
            mode.name,
            () {
              addOrUpdateData('settings', 'themeMode', mode.name);
              J3Tunes.updateAppState(context, newThemeMode: mode);
              Navigator.pop(context);
            },
            themeMode == mode ? activatedColor : inactivatedColor,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    Color activatedColor,
    Color inactivatedColor,
  ) {
    final availableLanguages = appLanguages.keys.toList();
    final activeLanguageCode = Localizations.localeOf(context).languageCode;
    final activeScriptCode = Localizations.localeOf(context).scriptCode;
    final activeLanguageFullCode = activeScriptCode != null
        ? '$activeLanguageCode-$activeScriptCode'
        : activeLanguageCode;

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottmomPadding,
        itemCount: availableLanguages.length,
        itemBuilder: (context, index) {
          final language = availableLanguages[index];
          final newLocale = getLocaleFromLanguageCode(appLanguages[language]);
          final newLocaleFullCode = newLocale.scriptCode != null
              ? '${newLocale.languageCode}-${newLocale.scriptCode}'
              : newLocale.languageCode;

          final borderRadius = getItemBorderRadius(
            index,
            availableLanguages.length,
          );

          return BottomSheetBar(
            language,
            () {
              addOrUpdateData('settings', 'language', newLocaleFullCode);
              J3Tunes.updateAppState(context, newLocale: newLocale);
              showToast(context, context.l10n!.languageMsg);
              Navigator.pop(context);
            },
            activeLanguageFullCode == newLocaleFullCode
                ? activatedColor
                : inactivatedColor,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }

  void _showAudioQualityPicker(
    BuildContext context,
    Color activatedColor,
    Color inactivatedColor,
  ) {
    final availableQualities = ['low', 'medium', 'high'];

    showCustomBottomSheet(
      context,
      ListView.builder(
        shrinkWrap: true,
        physics: const BouncingScrollPhysics(),
        padding: commonListViewBottmomPadding,
        itemCount: availableQualities.length,
        itemBuilder: (context, index) {
          final quality = availableQualities[index];
          final isCurrentQuality = audioQualitySetting.value == quality;
          final borderRadius = getItemBorderRadius(
            index,
            availableQualities.length,
          );

          return BottomSheetBar(
            quality,
            () {
              addOrUpdateData('settings', 'audioQuality', quality);
              audioQualitySetting.value = quality;
              showToast(context, context.l10n!.audioQualityMsg);
              Navigator.pop(context);
            },
            isCurrentQuality ? activatedColor : inactivatedColor,
            borderRadius: borderRadius,
          );
        },
      ),
    );
  }

  void _toggleSystemColor(BuildContext context, bool value) {
    addOrUpdateData('settings', 'useSystemColor', value);
    useSystemColor.value = value;
    J3Tunes.updateAppState(
      context,
      newAccentColor: primaryColorSetting,
      useSystemColor: value,
    );
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _togglePureBlack(BuildContext context, bool value) {
    addOrUpdateData('settings', 'usePureBlackColor', value);
    usePureBlackColor.value = value;
    J3Tunes.updateAppState(context);
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _togglePredictiveBack(BuildContext context, bool value) {
    addOrUpdateData('settings', 'predictiveBack', value);
    predictiveBack.value = value;
    transitionsBuilder = value
        ? const PredictiveBackPageTransitionsBuilder()
        : const CupertinoPageTransitionsBuilder();
    J3Tunes.updateAppState(context);
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleBackgroundPlay(BuildContext context, bool value) {
    addOrUpdateData('settings', 'backgroundPlay', value);
    backgroundPlay.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleOfflineMode(BuildContext context, bool value) {
    addOrUpdateData('settings', 'offlineMode', value);
    offlineMode.value = value;
    showToast(context, context.l10n!.restartAppMsg);
  }

  void _toggleSponsorBlock(BuildContext context, bool value) {
    addOrUpdateData('settings', 'sponsorBlockSupport', value);
    sponsorBlockSupport.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _toggleDefaultRecommendations(BuildContext context, bool value) {
    addOrUpdateData('settings', 'defaultRecommendations', value);
    defaultRecommendations.value = value;
    showToast(context, context.l10n!.settingChangedMsg);
  }

  void _showClearSearchHistoryDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          submitMessage: context.l10n!.clear,
          confirmationMessage: context.l10n!.clearSearchHistoryQuestion,
          onCancel: () => {Navigator.of(context).pop()},
          onSubmit: () => {
            Navigator.of(context).pop(),
            searchHistory = [],
            deleteData('user', 'searchHistory'),
            showToast(context, '${context.l10n!.searchHistoryMsg}!'),
          },
        );
      },
    );
  }

  void _showClearRecentlyPlayedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ConfirmationDialog(
          submitMessage: context.l10n!.clear,
          confirmationMessage: context.l10n!.clearRecentlyPlayedQuestion,
          onCancel: () => {Navigator.of(context).pop()},
          onSubmit: () => {
            Navigator.of(context).pop(),
            userRecentlyPlayed = [],
            deleteData('user', 'recentlyPlayedSongs'),
            showToast(context, '${context.l10n!.recentlyPlayedMsg}!'),
          },
        );
      },
    );
  }

  Future<void> _backupUserData(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Text(context.l10n!.folderRestrictions),
          actions: <Widget>[
            TextButton(
              child: Text(context.l10n!.understand.toUpperCase()),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
    final response = await backupData(context);
    showToast(context, response);
  }

  // Widget _buildWidgetTestSection(BuildContext context) {
  //   return Column(
  //     children: [
  //       SectionHeader(title: 'Widget Testing'),
  //       CustomBar(
  //         'Test Widget Update',
  //         FluentIcons.play_24_filled,
  //         onTap: () async {
  //           await MusicWidgetService.updateWidget(
  //             songTitle: 'Test Song',
  //             artistName: 'Test Artist',
  //             albumArt: '',
  //             isPlaying: true,
  //             duration: '3:30',
  //             currentPosition: '1:15',
  //           );
  //           showToast(context, 'Widget Updated!');
  //         },
  //       ),
  //     ],
  //   );
  // }
}
