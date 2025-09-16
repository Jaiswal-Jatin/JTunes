import 'package:flutter/material.dart';
import 'package:j3tunes/utilities/responsive.dart';

/// A widget that provides different layouts based on screen size.
/// It uses [Responsive] breakpoints to determine whether to show
/// a mobile or desktop layout. This is the main entry point for
/// platform-adaptive UI, switching between the mobile-specific
/// and desktop/tablet-specific layouts.
class AdaptiveLayout extends StatelessWidget {
  const AdaptiveLayout({
    super.key,
    required this.mobileLayout,
    required this.desktopLayout,
  });

  /// The widget to display when the screen size is considered mobile.
  final WidgetBuilder mobileLayout;

  /// The widget to display when the screen size is considered desktop or tablet.
  final WidgetBuilder desktopLayout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Platform-specific check: Renders mobileLayout for mobile screen sizes
        // and desktopLayout for desktop screen sizes.
        if (Responsive.isMobile(context) || Responsive.isTablet(context)) {
          return mobileLayout(context);
        } else {
          // For desktop, use the desktop layout
          return desktopLayout(context);
        }
      },
    );
  }
}
