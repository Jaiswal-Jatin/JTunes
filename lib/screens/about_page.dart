// ignore_for_file: unused_import

import 'dart:io';

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:j3tunes/utilities/flutter_toast.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_apps_plus/device_apps_plus.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  String _appVersion = '...';
   String _lastUpdated = '...';

  @override
  void initState() {
    super.initState();
    _getAppVersion();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.about)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            _buildAppInfoSection(context),
            const SizedBox(height: 20),
            _buildDeveloperInfoSection(context),
            const SizedBox(height: 20),
            _buildExtraFeaturesSection(context),
          ],
        ),
      ),
    );
  }

  Future<void> _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${packageInfo.version}+${packageInfo.buildNumber}';
      });
    }
  }

  void _launchURL(String url) {
    launchURL(Uri.parse(url));
  }

  Future<void> _shareApp() async {
    // Share the Play Store link.
    _sharePlayStoreLink();
  }

  void _sendFeedback() {
    const feedbackUrl =
        'https://docs.google.com/forms/d/e/1FAIpQLScb1JYrabx2XlfSh-AvVBJqY52PQHKOdV1q7DKu_AX3rhoE9w/viewform?usp=header';
    _launchURL(feedbackUrl);
  }

  void _sharePlayStoreLink() {
    Share.share(
      'Check out J3Tunes, a cool music app! Download it here: https://play.google.com/store/apps/details?id=com.jatin.J3Tunes',
      subject: 'J3Tunes Music App',
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildAppInfoSection(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.asset('assets/images/JTunes.png', height: 80),
            const SizedBox(height: 12),
            Text(
              'J3Tunes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your personal gateway to the world of music.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoChip('Version', _appVersion),
                // _buildInfoChip('Last Updated', _lastUpdated),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Column(
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        const SizedBox(height: 2),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDeveloperInfoSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Developer'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [              
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                leading: const CircleAvatar(
                  radius: 28,
                  backgroundImage: AssetImage('assets/images/Jatin_Jaiswal.jpeg'),
                ),
                title: const Text(
                  'Jatin Jaiswal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('App Developer'),
                trailing: IconButton(
                  icon: const Icon(FluentIcons.open_24_regular),
                  onPressed: () => _launchURL('https://www.linkedin.com/in/jatin-jaiswal-95435121b/'),
                ),
              ),              
              const Divider(height: 1),
              ListTile(
                leading: const Icon(FluentIcons.mail_24_regular),
                title: const Text('jatinjaiswal2002@gmail.com'),
                onTap: () => _launchURL('mailto:jatinjaiswal2002@gmail.com'),
              ),
              const Divider(height: 1),
              // ListTile(
              //   leading: const Icon(FluentIcons.globe_24_regular),
              //   title: const Text('Portfolio / Website'),
              //   onTap: () => _launchURL('https://jatinjaiswal.netlify.app/'),
              // ),
              // const Divider(height: 1),
              ListTile(
                leading: const Icon(FluentIcons.code_24_regular),
                title: const Text('GitHub'),
                onTap: () => _launchURL('https://github.com/jatin-jaiswal'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExtraFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, 'Support & Feedback'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(FluentIcons.star_24_regular),
                title: const Text('Rate Us'),
                onTap: () => _launchURL(
                    'https://play.google.com/store/apps/details?id=com.jatin.J3Tunes'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(FluentIcons.share_24_regular),
                title: const Text('Share App'),
                onTap: _shareApp,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(FluentIcons.chat_24_regular),
                title: const Text('Send Feedback'),
                onTap: _sendFeedback,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
