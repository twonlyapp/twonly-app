import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/subscription.keys.dart';
import 'package:twonly/src/model/purchasable_product.model.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:url_launcher/url_launcher.dart';

// Gives the option to override in tests.
class IAPConnection {
  static InAppPurchase? _instance;
  static set instance(InAppPurchase value) {
    _instance = value;
  }

  static InAppPurchase get instance {
    _instance ??= InAppPurchase.instance;
    return _instance!;
  }
}

enum StoreState { loading, available, notAvailable }

enum _VerificationResult { verified, rejected, retry }

class _PendingPurchase {
  _PendingPurchase(this.details, {required this.userInitiated})
    : requiresVerification = details.status == PurchaseStatus.purchased;

  PurchaseDetails details;
  bool userInitiated;
  bool requiresVerification;
  int attempts = 0;
  DateTime? retryAfter;
}

class PurchasesProvider with ChangeNotifier, DiagnosticableTreeMixin {
  PurchasesProvider() {
    _subscription = iapConnection.purchaseStream.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    _apiSub = apiService.events.listen((event) {
      if (event.kind == ApiEventKind.planUpdated) {
        updatePlan(planFromString(event.message ?? ''));
      }

      if (event.kind == ApiEventKind.connectionStateChanged) {
        _receivedConnectionEvent = true;
        _authenticated = event.state == ApiConnectionState.authenticated;
        try {
          if (userService.isUserCreated) {
            updatePlan(
              planFromString(userService.currentUser.subscriptionPlan),
            );
          }
        } catch (e) {
          Log.error(e);
        }
      }
      if (event.kind == ApiEventKind.authenticated) {
        _receivedConnectionEvent = true;
        _authenticated = true;
      }
      if (_authenticated) _enqueue(_retryPendingPurchases);
    });

    if (userService.isUserCreated) {
      updatePlan(planFromString(userService.currentUser.subscriptionPlan));
    }

    unawaited(_loadConnectionState());
    unawaited(loadPurchases());
    Log.info('PurchasesProvider: constructor finished');
  }

  SubscriptionPlan plan = SubscriptionPlan.Free;
  StoreState storeState = StoreState.loading;
  List<PurchasableProduct> products = [];

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase iapConnection = IAPConnection.instance;

  late StreamSubscription<ApiEvent> _apiSub;
  String? _buyingProductId;
  bool _disposed = false;
  bool _authenticated = false;
  bool _receivedConnectionEvent = false;
  Future<void> _purchaseQueue = Future<void>.value();
  Future<void>? _loadingPurchases;
  Timer? _retryTimer;
  final _pendingPurchases = <String, _PendingPurchase>{};
  final _resolvedPurchases = <String>{};
  final _completedPurchases = <String>{};
  static const _retryDelay = Duration(seconds: 30);
  static const _maxAttempts = 3;

  Future<void> _loadConnectionState() async {
    try {
      final state = await RustApi.connectionState();
      if (_disposed || _receivedConnectionEvent) return;
      _authenticated = state == ApiConnectionState.authenticated;
      if (_authenticated) _enqueue(_retryPendingPurchases);
    } catch (e) {
      Log.error(e);
    }
  }

  void updatePlan(SubscriptionPlan newPlan) {
    if (_disposed || plan == newPlan) return;
    plan = newPlan;
    notifyListeners();
  }

  Future<void> loadPurchases() {
    if (_disposed) return Future<void>.value();
    return _loadingPurchases ??= _loadPurchases();
  }

  Future<void> _loadPurchases() async {
    try {
      await _loadProductsAndRestore();
    } catch (e) {
      Log.error(e);
      if (!_disposed) {
        storeState = StoreState.notAvailable;
        notifyListeners();
      }
    } finally {
      _loadingPurchases = null;
    }
  }

  Future<void> _loadProductsAndRestore() async {
    final available = await iapConnection.isAvailable();
    if (_disposed) return;
    Log.info('PurchasesProvider: IAP available: $available');
    if (!available) {
      storeState = StoreState.notAvailable;
      Log.warn('Store is not available');
      notifyListeners();
      return;
    }
    const ids = <String>{
      SubscriptionKeys.proMonthly,
      SubscriptionKeys.proYearly,
      SubscriptionKeys.familyYearly,
    };
    final response = await iapConnection.queryProductDetails(ids);
    if (_disposed) return;
    if (response.notFoundIDs.isNotEmpty) {
      Log.warn(response.notFoundIDs);
    }
    products = response.productDetails.map(PurchasableProduct.new).toList();
    if (products.isEmpty) {
      Log.warn('Could not load any products from the store!');
    }
    storeState = StoreState.available;
    notifyListeners();

    try {
      await iapConnection.restorePurchases();
    } catch (e) {
      Log.error(e);
    }
  }

  Future<void> buy(PurchasableProduct product) async {
    if (_disposed || _buyingProductId != null) return;
    final purchaseParam = PurchaseParam(productDetails: product.productDetails);
    switch (product.id) {
      case SubscriptionKeys.proMonthly:
      case SubscriptionKeys.proYearly:
      case SubscriptionKeys.familyYearly:
        _buyingProductId = product.id;
        Log.info('User wants to buy ${product.id}');

        try {
          final started = await iapConnection.buyNonConsumable(
            purchaseParam: purchaseParam,
          );
          if (!started) _buyingProductId = null;
        } catch (_) {
          _buyingProductId = null;
          rethrow;
        }
      default:
        throw ArgumentError.value(
          product.productDetails,
          '${product.id} is not a known product',
        );
    }
  }

  void _enqueue(Future<void> Function() work) {
    _purchaseQueue = _purchaseQueue.then((_) async {
      if (_disposed) return;
      try {
        await work();
      } catch (e) {
        Log.error(e);
      }
    });
  }

  void _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) {
    _enqueue(() async {
      for (final purchaseDetails in purchaseDetailsList) {
        if (_disposed) return;
        await _handlePurchase(purchaseDetails);
      }
      if (!_disposed) notifyListeners();
    });
  }

  Future<_VerificationResult> _verifyPurchase(
    PurchaseDetails purchaseDetails, {
    required bool userInitiated,
  }) async {
    Log.info('verifying _verifyPurchase');
    if (Platform.isIOS) {
      try {
        var b64Data = purchaseDetails.verificationData.serverVerificationData
            .split('.')[1];

        final paddingNeeded = (4 - (b64Data.length % 4)) % 4;
        b64Data += '=' * paddingNeeded;

        final jsonData = base64Decode(b64Data);
        final data = jsonDecode(utf8.decode(jsonData)) as Map<String, dynamic>;
        final expiresDate = data['expiresDate'] as int;
        final dt = DateTime.fromMillisecondsSinceEpoch(
          expiresDate,
          isUtc: true,
        );
        if (dt.isBefore(DateTime.now())) {
          Log.warn('ExpiresDate is in the past: $dt');
          if (userInitiated) {
            await launchUrl(
              Uri.parse('https://apps.apple.com/account/subscriptions'),
              mode: LaunchMode.externalApplication,
            );
          }
          return _VerificationResult.rejected;
        }
      } catch (e) {
        Log.error(e);
      }
    }
    if (kDebugMode) {
      Log.info(purchaseDetails.productID);
      Log.info(purchaseDetails.verificationData.source);
    }
    final res = await rustApiResult(
      RustApi.ipaPurchase(
        productId: purchaseDetails.productID,
        source: purchaseDetails.verificationData.source,
        verificationData:
            purchaseDetails.verificationData.serverVerificationData,
      ),
    );
    if (_disposed) return _VerificationResult.retry;
    // plan is updated in the apiProvider, as the server updates its states and responses with
    // an ok authenticated which is processed in the apiProvider...
    if (res.isSuccess) {
      if (Platform.isAndroid) {
        await UserService.update((u) {
          u.subscriptionPlanIdStore = purchaseDetails.productID;
        });
      }
    }
    if (res.isError) {
      if (res.error == ErrorCode.IPAPaymentExpired &&
          userInitiated &&
          Platform.isIOS) {
        await launchUrl(
          Uri.parse('https://apps.apple.com/account/subscriptions'),
          mode: LaunchMode.externalApplication,
        );
      }
    }
    if (res.isSuccess) return _VerificationResult.verified;
    if (res.error == ErrorCode.IPAPaymentExpired ||
        res.error == ErrorCode.BadRequest ||
        res.error == ErrorCode.SignatureNotValid) {
      return _VerificationResult.rejected;
    }
    return _VerificationResult.retry;
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    Log.info(
      '_handlePurchase: ${purchaseDetails.productID}, ${purchaseDetails.status}',
    );
    final userInitiated = _buyingProductId == purchaseDetails.productID;
    if (purchaseDetails.status == PurchaseStatus.pending) return;
    if (userInitiated ||
        (purchaseDetails.productID.isEmpty &&
            (purchaseDetails.status == PurchaseStatus.error ||
                purchaseDetails.status == PurchaseStatus.canceled))) {
      _buyingProductId = null;
    }

    if (purchaseDetails.status == PurchaseStatus.error ||
        purchaseDetails.status == PurchaseStatus.canceled) {
      // An error is not a reason to replay the entire store purchase history.
      if (purchaseDetails.error != null) Log.error(purchaseDetails.error);
      try {
        if (purchaseDetails.pendingCompletePurchase) {
          await iapConnection.completePurchase(purchaseDetails);
        }
      } catch (e) {
        Log.error(e);
      }
      return;
    }

    final key = jsonEncode([
      purchaseDetails.verificationData.source,
      purchaseDetails.productID,
      purchaseDetails.purchaseID,
      purchaseDetails.transactionDate,
      purchaseDetails.verificationData.serverVerificationData,
    ]);
    // Include the receipt and transaction date so renewals are not suppressed
    // when the store reuses a purchase ID or token.
    final pending = _pendingPurchases.putIfAbsent(
      key,
      () => _PendingPurchase(purchaseDetails, userInitiated: userInitiated),
    );
    // StoreKit 2 restored events report no completion pending, even when an
    // earlier purchased event for this transaction still needs to be finished.
    if (purchaseDetails.pendingCompletePurchase ||
        !pending.details.pendingCompletePurchase) {
      pending.details = purchaseDetails;
    }
    pending
      ..userInitiated = pending.userInitiated || userInitiated
      ..requiresVerification =
          pending.requiresVerification ||
          purchaseDetails.status == PurchaseStatus.purchased;
    await _processPurchase(key, pending);
  }

  Future<void> _retryPendingPurchases() async {
    for (final entry in _pendingPurchases.entries.toList()) {
      if (_disposed) return;
      await _processPurchase(entry.key, entry.value);
    }
    _scheduleRetryTimer();
  }

  Future<void> _processPurchase(String key, _PendingPurchase pending) async {
    if (_disposed || pending.attempts >= _maxAttempts) return;
    if (pending.retryAfter?.isAfter(clock.now()) ?? false) return;
    final details = pending.details;
    final alreadyResolved = _resolvedPurchases.contains(key);
    // A routine restore only needs to register a missing entitlement. Read the
    // current plan here, after earlier events in the queue have finished.
    final needsVerification =
        !alreadyResolved &&
        (pending.requiresVerification ||
            pending.userInitiated ||
            !isPayingUser(plan));
    if (needsVerification && (!_authenticated || !userService.isUserCreated)) {
      return;
    }

    pending.attempts++;
    try {
      if (needsVerification) {
        final result = await _verifyPurchase(
          details,
          userInitiated: pending.userInitiated,
        );
        if (_disposed) return;
        if (result == _VerificationResult.retry) {
          _scheduleRetry(pending);
          return;
        }
        _resolvedPurchases.add(key);
      }
      if (_disposed) return;
      if (details.pendingCompletePurchase &&
          !_completedPurchases.contains(key)) {
        await iapConnection.completePurchase(details);
        _completedPurchases.add(key);
      }
      _pendingPurchases.remove(key);
    } catch (e) {
      Log.error(e);
      _scheduleRetry(pending);
    }
  }

  void _scheduleRetry(_PendingPurchase pending) {
    if (_disposed || pending.attempts >= _maxAttempts) return;
    pending.retryAfter = clock.now().add(_retryDelay);
    _scheduleRetryTimer();
  }

  void _scheduleRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
    if (_disposed || !_authenticated || !userService.isUserCreated) return;
    DateTime? nextAttempt;
    for (final pending in _pendingPurchases.values) {
      final retryAfter = pending.retryAfter;
      if (pending.attempts < _maxAttempts &&
          retryAfter != null &&
          (nextAttempt == null || retryAfter.isBefore(nextAttempt))) {
        nextAttempt = retryAfter;
      }
    }
    if (nextAttempt == null) return;
    final delay = nextAttempt.difference(clock.now());
    _retryTimer = Timer(delay.isNegative ? Duration.zero : delay, () {
      _retryTimer = null;
      _enqueue(_retryPendingPurchases);
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _retryTimer?.cancel();
    _pendingPurchases.clear();
    unawaited(_apiSub.cancel());
    unawaited(_subscription.cancel());
    super.dispose();
  }

  void _updateStreamOnDone() {
    unawaited(_subscription.cancel());
  }

  void _updateStreamOnError(dynamic error) {
    Log.error(error);
  }
}
