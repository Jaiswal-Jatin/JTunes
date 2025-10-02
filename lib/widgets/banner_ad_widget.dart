import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:j3tunes/services/ad_service.dart';

/// A reusable widget to display a banner ad.
///
/// It fetches a pre-loaded ad from the AdService to display efficiently.
class BannerAdWidget extends StatelessWidget {
  /// An optional index to cycle through the ad cache.
  /// Useful when showing multiple ads on the same screen.
  final int adIndex;

  const BannerAdWidget({super.key, this.adIndex = 0});

  @override
  Widget build(BuildContext context) {
    // Get a pre-loaded ad from the service.
    final bannerAd = AdService.instance.getBannerAd(adIndex);

    if (bannerAd != null) {
      return Center(
        child: SafeArea(
          child: SizedBox(
            width: bannerAd.size.width.toDouble(),
            height: bannerAd.size.height.toDouble(),
            child: AdWidget(ad: bannerAd),
          ),
        ),
      );
    }

    // If the ad is not loaded yet, show a placeholder or an empty box.
    return const SizedBox.shrink();
  }
}