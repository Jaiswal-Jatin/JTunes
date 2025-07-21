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

import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:j3tunes/widgets/no_artwork_cube.dart';
import 'package:j3tunes/widgets/spinner.dart';

class SongArtworkWidget extends StatelessWidget {
  const SongArtworkWidget({
    super.key,
    required this.size,
    required this.metadata,
    this.borderRadius = 10.0,
    this.errorWidgetIconSize = 20.0,
  });
  final double size;
  final MediaItem metadata;
  final double borderRadius;
  final double errorWidgetIconSize;

  // Helper function to get the best quality image URL
  String? _getBestImageUrl(MediaItem mediaItem) {
    // Priority: highResImage > artUri > lowResImage
    final highResImage = mediaItem.extras?['highResImage']?.toString();
    final artUri = mediaItem.artUri?.toString();
    final lowResImage = mediaItem.extras?['lowResImage']?.toString();
    
    if (highResImage != null && highResImage.isNotEmpty && highResImage != 'null') {
      return highResImage;
    }
    if (artUri != null && artUri.isNotEmpty && artUri != 'null') {
      return artUri;
    }
    if (lowResImage != null && lowResImage.isNotEmpty && lowResImage != 'null') {
      return lowResImage;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;
    if (metadata.artUri?.scheme == 'file') {
      imageWidget = Image.file(
        File(metadata.extras?['artWorkPath']),
        fit: BoxFit.cover,
      );
    } else {
      // Use the best quality image URL
      final imageUrl = _getBestImageUrl(metadata);
      imageWidget = CachedNetworkImage(
        key: ValueKey(imageUrl ?? metadata.artUri.toString()),
        width: size,
        height: size,
        imageUrl: imageUrl ?? metadata.artUri.toString(),
        imageBuilder: (context, imageProvider) => Image(
          image: imageProvider,
          fit: BoxFit.cover,
        ),
        placeholder: (context, url) => const Spinner(),
        errorWidget: (context, url, error) =>
            NullArtworkWidget(iconSize: errorWidgetIconSize),
      );
    }
    // Always crop/zoom the image everywhere
    return SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Transform.scale(
          scale: 1.4, // Crop/zoom all song images everywhere
          child: imageWidget,
        ),
      ),
    );
  }
}
