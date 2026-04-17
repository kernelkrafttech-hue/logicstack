import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'premium_service.dart';

class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  // Google test banner unit id. Replace with a real unit id before release.
  static const _testUnitId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    PremiumService.instance.addListener(_onPremiumChanged);
    if (!PremiumService.instance.isPremium) _loadAd();
  }

  void _onPremiumChanged() {
    if (PremiumService.instance.isPremium) {
      _ad?.dispose();
      if (mounted) setState(() => _loaded = false);
    } else if (_ad == null) {
      _loadAd();
    }
  }

  void _loadAd() {
    _ad = BannerAd(
      size: AdSize.banner,
      adUnitId: _testUnitId,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    PremiumService.instance.removeListener(_onPremiumChanged);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (PremiumService.instance.isPremium || !_loaded || _ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: _ad!.size.width.toDouble(),
      height: _ad!.size.height.toDouble(),
      child: AdWidget(ad: _ad!),
    );
  }
}
