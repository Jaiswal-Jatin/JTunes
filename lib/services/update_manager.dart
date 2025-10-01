

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/main.dart'; 
import 'package:j3tunes/services/router_service.dart';
import 'package:j3tunes/utilities/flutter_toast.dart'; 
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

const String backendUrl = 'https://jtunes-backend.onrender.com/latest-version'; 

Future<bool> checkAppUpdates({bool showNoUpdateMessage = false}) async {
  try {
    final dio = Dio();
    final response = await dio.get(backendUrl);

    if (response.statusCode != 200) {
      logger.log(
        'Backend update check failed with status code ${response.statusCode}',
        null,
        null,
      );
      if (showNoUpdateMessage) {
        showToast(NavigationManager().context, NavigationManager().context.l10n!.error);
      }
      return false;
    }

    final updateInfo = response.data as Map<String, dynamic>;
    final latestVersion = updateInfo['version'] as String;
    final apkUrl = updateInfo['apk_url'] as String;
    final updateNotes = updateInfo['update_notes'] as String?;
    final forceUpdate = updateInfo['force_update'] as bool;

    if (currentAppVersion == null) {
      logger.log('Current app version not available, skipping update check.', null, null);
      if (showNoUpdateMessage) {
        showToast(NavigationManager().context, NavigationManager().context.l10n!.error);
      }
      return false;
    }

    if (!isLatestVersionHigher(currentAppVersion!, latestVersion)) {
      logger.log('App is up to date.', null, null);
      if (showNoUpdateMessage) {
        showToast(NavigationManager().context, NavigationManager().context.l10n!.appIsUpdated);
      }
      return false;
    }

    // Show update dialog
    await showDialog(
      context: NavigationManager().context,
      barrierDismissible: !forceUpdate,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => !forceUpdate,
          child: UpdateDialog(
            version: latestVersion,
            notes: updateNotes,
            apkUrl: apkUrl,
            isForced: forceUpdate,
          ),
        );
      },
    );
    return true; // Update dialog was shown
  } catch (e, stackTrace) {
    logger.log('Error in checkAppUpdates', e, stackTrace);
    if (showNoUpdateMessage) {
      showToast(NavigationManager().context, NavigationManager().context.l10n!.error);
    }
    return false;
  }
}

class UpdateDialog extends StatefulWidget {
  const UpdateDialog({
    super.key,
    required this.version,
    this.notes,
    required this.apkUrl,
    required this.isForced,
  });

  final String version;
  final String? notes;
  final String apkUrl;
  final bool isForced;

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  bool _isDownloading = false;
  double _progress = 0.0;
  String _status = '';

  Future<void> _downloadAndInstall() async {
    setState(() {
      _isDownloading = true;
      _status = 'Starting download...';
    });

    try {
      final dio = Dio();
      final dir = await getExternalStorageDirectory();
      final savePath = '${dir?.path}/J3Tunes-v${widget.version}.apk';

      await dio.download(
        widget.apkUrl,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _progress = received / total;
              _status =
                  'Downloading... ${(received / 1024 / 1024).toStringAsFixed(1)}MB / ${(total / 1024 / 1024).toStringAsFixed(1)}MB';
            });
          }
        },
      );

      setState(() {
        _status = 'Download complete. Opening installer...';
      });

      // Use url_launcher to open the downloaded APK
      final fileUri = Uri.file(savePath);
      if (await canLaunchUrl(fileUri)) {
        await launchUrl(fileUri);
      } else {
        throw Exception('Could not launch $fileUri');
      }
    } catch (e, s) {
      logger.log('Update Download Error', e, s);
      setState(() {
        _isDownloading = false;
        _status = 'Download failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Update Available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A new version (v${widget.version}) is available.'),
          if (widget.notes != null && widget.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Update Notes:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(widget.notes!),
          ],
          if (_isDownloading) ...[
            const SizedBox(height: 20),
            LinearProgressIndicator(value: _progress),
            const SizedBox(height: 8),
            Text(_status, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
      actions: [
        if (!widget.isForced && !_isDownloading)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n!.cancel.toUpperCase()),
          ),
        if (!_isDownloading)
          FilledButton(
            onPressed: _downloadAndInstall,
            child: Text(context.l10n!.download.toUpperCase()),
          ),
      ],
    );
  }
}

bool isLatestVersionHigher(String appVersion, String latestVersion) {
  final parsedAppVersion = appVersion.split('.');
  final parsedAppLatestVersion = latestVersion.split('.');
  final length =
      parsedAppVersion.length > parsedAppLatestVersion.length
          ? parsedAppVersion.length
          : parsedAppLatestVersion.length;
  for (var i = 0; i < length; i++) {
    final value1 =
        i < parsedAppVersion.length ? int.parse(parsedAppVersion[i]) : 0;
    final value2 =
        i < parsedAppLatestVersion.length
            ? int.parse(parsedAppLatestVersion[i])
            : 0;
    if (value2 > value1) {
      return true;
    } else if (value2 < value1) {
      return false;
    }
  }

  return false;
}
