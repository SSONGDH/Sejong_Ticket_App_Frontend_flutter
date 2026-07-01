import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

typedef DonatePurchaseFeedback = void Function(String message, {bool isError});

class DonatePurchaseService {
  DonatePurchaseService._();

  static final DonatePurchaseService instance = DonatePurchaseService._();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isAvailable = false;
  bool _purchaseInProgress = false;
  DonatePurchaseFeedback? onFeedback;

  bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  bool get isAvailable => _isAvailable;

  String get productId =>
      dotenv.env['IAP_DONATE_PRODUCT_ID'] ?? 'donate_support';

  Future<void> initialize() async {
    if (!isSupported) return;

    _isAvailable = await _iap.isAvailable();
    await _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdated,
      onError: (Object error) {
        _purchaseInProgress = false;
        onFeedback?.call('결제 처리 중 오류가 발생했습니다.', isError: true);
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> buyDonate() async {
    if (!isSupported) {
      onFeedback?.call('이 기기에서는 인앱 결제를 지원하지 않습니다.', isError: true);
      return;
    }
    if (!_isAvailable) {
      onFeedback?.call('스토어 결제를 사용할 수 없습니다.', isError: true);
      return;
    }
    if (_purchaseInProgress) return;

    _purchaseInProgress = true;
    try {
      final response = await _iap.queryProductDetails({productId});
      if (response.notFoundIDs.isNotEmpty || response.productDetails.isEmpty) {
        onFeedback?.call(
          '후원 상품을 찾을 수 없습니다. Play Console에 상품을 등록해 주세요.',
          isError: true,
        );
        return;
      }

      final product = response.productDetails.first;
      final started = await _iap.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        onFeedback?.call('결제를 시작하지 못했습니다.', isError: true);
      }
    } catch (_) {
      onFeedback?.call('결제를 시작하지 못했습니다.', isError: true);
    } finally {
      _purchaseInProgress = false;
    }
  }

  Future<void> _onPurchaseUpdated(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;

      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
          onFeedback?.call('후원해 주셔서 감사합니다!');
          break;
        case PurchaseStatus.restored:
          onFeedback?.call('후원 내역이 복원되었습니다.');
          break;
        case PurchaseStatus.error:
          onFeedback?.call(
            purchase.error?.message ?? '결제에 실패했습니다.',
            isError: true,
          );
          break;
        case PurchaseStatus.canceled:
          onFeedback?.call('결제가 취소되었습니다.', isError: true);
          break;
      }

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }
    }
    _purchaseInProgress = false;
  }
}
