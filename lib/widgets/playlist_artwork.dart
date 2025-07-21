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

import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/utilities/common_variables.dart';
import 'package:j3tunes/widgets/no_artwork_cube.dart';

class PlaylistArtwork extends StatelessWidget {
  const PlaylistArtwork({
    super.key,
    required this.playlistArtwork,
    this.playlistTitle,
    this.cubeIcon = FluentIcons.music_note_1_24_regular,
    this.iconSize = 30,
    this.size = 220,
  });

  final String? playlistArtwork;
  final String? playlistTitle;
  final IconData cubeIcon;
  final double iconSize;
  final double size;

  Widget _nullArtwork() => NullArtworkWidget(
        icon: cubeIcon,
        iconSize: iconSize,
        size: size,
        title: playlistTitle,
      );

  @override
  Widget build(BuildContext context) {
    final image = playlistArtwork;
    if (image == null) return _nullArtwork();

    Widget imageWidget;
    if (image.startsWith('data:image')) {
      final commaIdx = image.indexOf(',');
      if (commaIdx == -1) return _nullArtwork();
      try {
        final bytes = base64Decode(image.substring(commaIdx + 1));
        imageWidget = Image.memory(
          bytes,
          height: size,
          width: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _nullArtwork(),
        );
      } catch (_) {
        return _nullArtwork();
      }
    } else if (image.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        key: Key(image),
        height: size,
        width: size,
        imageUrl: image,
        fit: BoxFit.cover,
        imageBuilder: (_, imageProvider) => ClipRRect(
          borderRadius: commonBarRadius,
          child: Image(
            image: imageProvider,
            height: size,
            width: size,
            fit: BoxFit.cover,
          ),
        ),
        placeholder: (_, __) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: commonBarRadius,
          ),
          alignment: Alignment.center,
          child: Icon(
            cubeIcon,
            size: iconSize,
            color: Colors.grey.shade700,
          ),
        ),
        errorWidget: (_, __, ___) => _nullArtwork(),
      );
    } else {
      imageWidget = _nullArtwork();
    }

    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: commonBarRadius,
        child: Transform.scale(
          scale: 1.4, // Crop/zoom all playlist images everywhere
          child: imageWidget,
        ),
      ),
    );
  }
}
