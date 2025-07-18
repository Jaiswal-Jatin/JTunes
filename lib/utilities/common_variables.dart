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

import 'package:flutter/material.dart';

const recommendedCubesNumber = 8;

const commonSingleChildScrollViewPadding = EdgeInsets.symmetric(horizontal: 10);
const commonBarPadding = EdgeInsets.symmetric(horizontal: 8);
var commonBarRadius = BorderRadius.circular(18);
var commonBarTitleStyle = const TextStyle(
  fontSize: 15,
  fontWeight: FontWeight.bold,
);

const commonCustomBarRadius = BorderRadius.all(Radius.circular(18));
const commonCustomBarRadiusFirst = BorderRadius.vertical(
  top: Radius.circular(18),
);
const commonCustomBarRadiusLast = BorderRadius.vertical(
  bottom: Radius.circular(18),
);

const commonListViewBottmomPadding = EdgeInsets.only(bottom: 8);

const commonBarContentPadding = EdgeInsets.symmetric(
  vertical: 12,
  horizontal: 10,
);

// Add this variable for max song duration
final ValueNotifier<int> maxSongDurationMinutes = ValueNotifier<int>(6);
