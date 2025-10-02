import 'dart:io';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A service to manage and cache AdMob banner ads.
/// This helps in reusing ads in lists and avoiding frequent reloads.
class AdService {
  // Singleton pattern to ensure only one instance of the service.
  AdService._privateConstructor();
  static final AdService instance = AdService._privateConstructor();

  final Map<int, BannerAd> _bannerAds = {};
  final Map<int, bool> _isAdLoaded = {};
  final int _maxAds = 5; // Maximum number of ads to cache.

  // Use your real Ad Unit ID here or Google's test ID.
  final String _adUnitId = Platform.isAndroid
      ? 'ca-app-pub-6428573761016390/1150095091' // Your Real Android Ad Unit ID
      : 'ca-app-pub-3940256099942544/2934735716'; // iOS Test ID

  /// Initializes the ad service by pre-loading a pool of banner ads.
  void initialize() {
    for (int i = 0; i < _maxAds; i++) {
      _loadAd(i);
    }
  }

  /// Loads a banner ad for a given index.
  void _loadAd(int index) {
    if (_bannerAds.containsKey(index)) {
      _bannerAds[index]?.dispose();
    }

    _isAdLoaded[index] = false;

    final bannerAd = BannerAd(
      size: AdSize.banner,
      adUnitId: _adUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          _bannerAds[index] = ad as BannerAd;
          _isAdLoaded[index] = true;
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          // Optional: Retry loading after a delay.
          Future.delayed(const Duration(seconds: 30), () => _loadAd(index));
        },
      ),
    );
    bannerAd.load();
  }

  /// Gets a loaded banner ad for a given index.
  /// The index is used to cycle through the cached ads.
  BannerAd? getBannerAd(int index) {
    final adIndex = index % _maxAds;
    if (_isAdLoaded[adIndex] == true) {
      return _bannerAds[adIndex];
    }
    return null;
  }

  /// Disposes all cached ads.
  void dispose() {
    for (final ad in _bannerAds.values) {
      ad.dispose();
    }
    _bannerAds.clear();
    _isAdLoaded.clear();
  }
}