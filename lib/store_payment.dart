import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

enum StorePaymentOutcome { paid, failed, cancelled, unavailable }

/// Card payment of the public try-on through Google Play Billing / Apple
/// StoreKit. A generated image is digital content, so both stores require
/// their own billing; the customer pays with the card of their store account.
///
/// The product is a consumable created in Play Console and App Store Connect
/// with the id [productId] (override with --dart-define=TRYON_PRODUCT_ID=...).
/// Web and desktop builds keep the demo dialog (see [supported]).
class StorePayment {
  StorePayment._();
  static final instance = StorePayment._();
  static const productId = String.fromEnvironment(
    'TRYON_PRODUCT_ID',
    defaultValue: 'digiwearit_tryon_unlock',
  );
  static const _forceDemo = bool.fromEnvironment('DEMO_PAYMENT');
  static bool get supported =>
      !kIsWeb &&
      !_forceDemo &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  InAppPurchase get _store => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _updates;
  Completer<StorePaymentOutcome>? _pending;
  ProductDetails? product;

  /// Listens to store updates; called at startup so purchases interrupted by
  /// an app kill are still acknowledged (Google refunds unacknowledged ones).
  void start() {
    if (!supported || _updates != null) return;
    _updates = _store.purchaseStream.listen(
      _handle,
      onError: (Object error) {
        debugPrint('Store purchase stream failed: $error');
        _finish(StorePaymentOutcome.failed);
      },
    );
  }

  /// Localized store product (price in the customer's currency), or null when
  /// billing is unavailable or the product is not configured.
  Future<ProductDetails?> load() async {
    if (!supported) return null;
    start();
    if (product != null) return product;
    try {
      if (!await _store.isAvailable()) return null;
      final response = await _store.queryProductDetails({productId});
      if (response.notFoundIDs.isNotEmpty)
        debugPrint('Store product not configured: ${response.notFoundIDs}');
      if (response.productDetails.isEmpty) return null;
      return product = response.productDetails.first;
    } catch (error) {
      debugPrint('Store products unavailable: $error');
      return null;
    }
  }

  Future<StorePaymentOutcome> buy() async {
    if (_pending != null) return _pending!.future;
    final details = await load();
    if (details == null) return StorePaymentOutcome.unavailable;
    final completer = _pending = Completer<StorePaymentOutcome>();
    try {
      final started = await _store.buyConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      if (!started) _finish(StorePaymentOutcome.failed);
    } catch (error) {
      debugPrint('Store purchase failed to start: $error');
      _finish(StorePaymentOutcome.failed);
    }
    return completer.future;
  }

  Future<void> _handle(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.productID != productId) continue;
      switch (purchase.status) {
        case PurchaseStatus.pending:
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _finish(StorePaymentOutcome.paid);
        case PurchaseStatus.canceled:
          _finish(StorePaymentOutcome.cancelled);
        case PurchaseStatus.error:
          debugPrint('Store purchase error: ${purchase.error}');
          _finish(StorePaymentOutcome.failed);
      }
      if (purchase.pendingCompletePurchase)
        await _store.completePurchase(purchase);
    }
  }

  void _finish(StorePaymentOutcome outcome) {
    final pending = _pending;
    _pending = null;
    if (pending != null && !pending.isCompleted) pending.complete(outcome);
  }
}
