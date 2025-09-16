import 'package:flutter/material.dart';

/// Defines responsive breakpoints for different screen sizes.
/// These breakpoints are used to adapt the UI for mobile, tablet, and desktop
/// platforms, ensuring a consistent user experience across devices.
class Responsive {
  /// The maximum width for a mobile layout. Screens smaller than this will be
  /// considered mobile.
  static const double mobileBreakpoint = 600;

  /// The maximum width for a tablet layout. Screens between [mobileBreakpoint]
  /// and this value will be considered tablet. Screens larger than this will
  /// be considered desktop.
  static const double tabletBreakpoint = 1000;

  /// Checks if the current screen width corresponds to a mobile device.
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  /// Checks if the current screen width corresponds to a tablet device.
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < tabletBreakpoint;

  /// Checks if the current screen width corresponds to a desktop device.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletBreakpoint;
}
