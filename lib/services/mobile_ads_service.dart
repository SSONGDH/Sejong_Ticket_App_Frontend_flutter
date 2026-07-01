import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class MobileAdsService {
  MobileAdsService._();

  static Future<void>? _initFuture;

  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  static Future<void> ensureInitialized() {
    if (!isSupported) {
      return Future.value();
    }
    _initFuture ??= MobileAds.instance.initialize();
    return _initFuture!;
  }
}
