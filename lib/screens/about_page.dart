// ignore_for_file: unused_import

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

import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/API/version.dart';
import 'package:j3tunes/extensions/l10n.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/utilities/url_launcher.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n!.about)),
      body: SingleChildScrollView(
        padding: commonSingleChildScrollViewPadding,
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 15),
              child: Text(
                'J3Tunes',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'paytoneOne',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const Divider(color: Colors.white24, thickness: 0.8, height: 20),
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(8),
                leading: Container(
                  height: 50,
                  width: 50,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    image: DecorationImage(
                      fit: BoxFit.fill,
                      image: AssetImage(
                        'assets/images/Photo .jpg',
                      ),
                    ),
                  ),
                ),
                title: const Text(
                  'Jatin Jaiswal',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: const Text('APP Developer'),
                // trailing: Wrap(
                //   children: <Widget>[
                //     // IconButton(
                //     //   icon: const Icon(FluentIcons.code_24_filled),
                //     //   tooltip: 'Github',
                //     //   onPressed: () {
                //     //     launchURL(Uri.parse('https://github.com/gokadzev'));
                //     //   },
                //     // ),
                //     // IconButton(
                //     //   icon: const Icon(FluentIcons.globe_24_filled),
                //     //   tooltip: 'Website',
                //     //   onPressed: () {
                //     //     launchURL(Uri.parse('https://gokadzev.github.io'));
                //     //   },
                //     // ),
                //   ],
                // ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
