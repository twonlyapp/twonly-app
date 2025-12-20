import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/subscription.keys.dart';
import 'package:twonly/src/model/purchases/purchasable_product.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';

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

class PurchasesProvider with ChangeNotifier, DiagnosticableTreeMixin {
  PurchasesProvider() {
    final purchaseUpdated = iapConnection.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    forceIpaCheck = Timer(const Duration(seconds: 10), () {
      Log.warn('Force Ipa check was not stopped. Requesting forced check...');
      apiService.forceIpaCheck();
    });
    loadPurchases();
  }

  late Timer forceIpaCheck;

  SubscriptionPlan plan = SubscriptionPlan.Free;
  StoreState storeState = StoreState.loading;
  List<PurchasableProduct> products = [];

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase iapConnection = IAPConnection.instance;

  void updatePlan(SubscriptionPlan newPlan) {
    plan = newPlan;
    notifyListeners();
  }

  Future<void> loadPurchases() async {
    final available = await iapConnection.isAvailable();
    if (!available) {
      storeState = StoreState.notAvailable;
      Log.error('Store is not available');
      notifyListeners();
      return;
    }
    const ids = <String>{
      SubscriptionKeys.proMonthly,
      SubscriptionKeys.proYearly,
      SubscriptionKeys.familyYearly,
    };
    final response = await iapConnection.queryProductDetails(ids);
    if (response.notFoundIDs.isNotEmpty) {
      Log.error(response.notFoundIDs);
    }
    products = response.productDetails.map(PurchasableProduct.new).toList();
    if (products.isEmpty) {
      Log.error('Could not load any products from the store!');
    }
    storeState = StoreState.available;
    notifyListeners();

    await iapConnection.restorePurchases();
  }

  Future<void> buy(PurchasableProduct product) async {
    Log.info('User wants to buy ${product.id}');
    final purchaseParam = PurchaseParam(productDetails: product.productDetails);
    switch (product.id) {
      // case storeKeyConsumable:
      //   await iapConnection.buyConsumable(purchaseParam: purchaseParam);
      case SubscriptionKeys.proMonthly:
      case SubscriptionKeys.proYearly:
      case SubscriptionKeys.familyYearly:
        await iapConnection.buyNonConsumable(purchaseParam: purchaseParam);
      default:
        throw ArgumentError.value(
          product.productDetails,
          '${product.id} is not a known product',
        );
    }
  }

  Future<void> _onPurchaseUpdate(
    List<PurchaseDetails> purchaseDetailsList,
  ) async {
    for (final purchaseDetails in purchaseDetailsList) {
      await _handlePurchase(purchaseDetails);
    }
    notifyListeners();
  }

  Future<bool> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    Log.info(purchaseDetails.productID);
    Log.info(purchaseDetails.verificationData.serverVerificationData);
    Log.info(purchaseDetails.verificationData.source);
    final res = await apiService.ipaPurchase(
      purchaseDetails.productID,
      purchaseDetails.verificationData.source,
      purchaseDetails.verificationData.serverVerificationData,
    );
    return res.isSuccess;
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    var validPurchase = false;
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      Log.info('purchased: ${purchaseDetails.productID}');
      validPurchase = await _verifyPurchase(purchaseDetails);
      if (validPurchase) {
        var plan = SubscriptionPlan.Pro;
        if (purchaseDetails.productID.contains('family')) {
          plan = SubscriptionPlan.Family;
        }
        await updateUserdata((u) {
          u
            ..subscriptionPlan = plan.name
            ..subscriptionPlanIdStore = purchaseDetails.productID;
          return u;
        });
        updatePlan(plan);
      }
    }
    if (purchaseDetails.status == PurchaseStatus.restored) {
      // there is a
      forceIpaCheck.cancel();

      if (gUser.subscriptionPlan != SubscriptionPlan.Family.name ||
          gUser.subscriptionPlan != SubscriptionPlan.Pro.name) {
        // app was installed on some one other...
        // subscription is handled on the server, so on a new device the subscription comes from the server again...
      }
    }

    if (purchaseDetails.pendingCompletePurchase) {
      await iapConnection.completePurchase(purchaseDetails);
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  void _updateStreamOnDone() {
    _subscription.cancel();
  }

  void _updateStreamOnError(dynamic error) {
    // Handle error here
  }
}
