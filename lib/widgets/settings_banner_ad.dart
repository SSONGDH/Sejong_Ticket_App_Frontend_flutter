import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:passtime/services/mobile_ads_service.dart';

class SettingsBannerAd extends StatefulWidget {
  const SettingsBannerAd({super.key});

  @override
  State<SettingsBannerAd> createState() => _SettingsBannerAdState();
}

class _SettingsBannerAdState extends State<SettingsBannerAd> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  bool get _isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _adUnitId {
    if (Platform.isAndroid) {
      return dotenv.env['ADMOB_SETTINGS_BANNER_ANDROID'] ??
          'ca-app-pub-3940256099942544/6300978111';
    }
    return dotenv.env['ADMOB_SETTINGS_BANNER_IOS'] ??
        'ca-app-pub-3940256099942544/2934735716';
  }

  @override
  void initState() {
    super.initState();
    if (_isSupported) {
      _loadAd();
    }
  }

  Future<void> _loadAd() async {
    try {
      await MobileAdsService.ensureInitialized();
    } catch (_) {
      return;
    }
    if (!mounted) return;

    _bannerAd = BannerAd(
      adUnitId: _adUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) return;
          setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (!mounted) return;
          setState(() {
            _bannerAd = null;
            _isLoaded = false;
          });
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSupported || !_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: ColoredBox(
        color: Colors.white,
        child: SizedBox(
          width: _bannerAd!.size.width.toDouble(),
          height: _bannerAd!.size.height.toDouble(),
          child: AdWidget(ad: _bannerAd!),
        ),
      ),
    );
  }
}
