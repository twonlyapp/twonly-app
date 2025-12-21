import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:twonly/globals.dart';
import 'package:twonly/src/constants/subscription.keys.dart';
import 'package:twonly/src/model/protobuf/api/websocket/error.pb.dart';
import 'package:twonly/src/model/purchases/purchasable_product.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/storage.dart';
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

Timer? globalForceIpaCheck;

class PurchasesProvider with ChangeNotifier, DiagnosticableTreeMixin {
  PurchasesProvider() {
    final purchaseUpdated = iapConnection.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _updateStreamOnDone,
      onError: _updateStreamOnError,
    );

    loadPurchases();
  }

  SubscriptionPlan plan = SubscriptionPlan.Free;
  StoreState storeState = StoreState.loading;
  List<PurchasableProduct> products = [];

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final InAppPurchase iapConnection = IAPConnection.instance;

  bool _userTriggeredBuyButton = false;

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

    final user = await getUser();
    if (user != null && isPayingUser(planFromString(user.subscriptionPlan))) {
      Log.info('Started IPA timer for verification.');
      globalForceIpaCheck = Timer(const Duration(seconds: 5), () async {
        Log.warn('Force Ipa check was not stopped. Requesting forced check...');
        await apiService.forceIpaCheck();
      });
    }

    await iapConnection.restorePurchases();
  }

  Future<void> buy(PurchasableProduct product) async {
    final purchaseParam = PurchaseParam(productDetails: product.productDetails);
    switch (product.id) {
      // case storeKeyConsumable:
      //   await iapConnection.buyConsumable(purchaseParam: purchaseParam);
      case SubscriptionKeys.proMonthly:
      case SubscriptionKeys.proYearly:
      case SubscriptionKeys.familyYearly:
        _userTriggeredBuyButton = true;
        Log.info('User wants to buy ${product.id}');

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
    if (kDebugMode) {
      Log.info(purchaseDetails.productID);
      Log.info(purchaseDetails.verificationData.serverVerificationData);
      // if (Platform.isIOS) {
      // final data = purchaseDetails.verificationData.serverVerificationData;
      // printWrapped(data);
      // final datas = data.split('.')[1];
      // printWrapped(datas);
      // }
      Log.info(purchaseDetails.verificationData.source);
    }
    final res = await apiService.ipaPurchase(
      purchaseDetails.productID,
      purchaseDetails.verificationData.source,
      purchaseDetails.verificationData.serverVerificationData,
    );
    // plan is updated in the apiProvider, as the server updates its states and responses with
    // an ok authenticated which is processed in the apiProvider...
    if (res.isSuccess) {
      if (Platform.isAndroid) {
        await updateUserdata((u) {
          u.subscriptionPlanIdStore = purchaseDetails.productID;
          return u;
        });
      }
    }
    if (res.isError) {
      if (res.error == ErrorCode.IPAPaymentExpired &&
          _userTriggeredBuyButton &&
          Platform.isIOS) {
        await launchUrl(
          Uri.parse('https://apps.apple.com/account/subscriptions'),
          mode: LaunchMode.externalApplication,
        );
      }
    }
    return res.isSuccess;
  }

  Future<void> _handlePurchase(PurchaseDetails purchaseDetails) async {
    Log.info(
      '_handlePurchase: ${purchaseDetails.productID}, ${purchaseDetails.status}',
    );
    if (purchaseDetails.status == PurchaseStatus.purchased) {
      await _verifyPurchase(purchaseDetails);
    }
    if (purchaseDetails.status == PurchaseStatus.restored &&
        purchaseDetails.error == null) {
      globalForceIpaCheck?.cancel();

      final user = await getUser();

      if (user != null &&
          (user.subscriptionPlan != SubscriptionPlan.Family.name &&
              user.subscriptionPlan != SubscriptionPlan.Pro.name)) {
        for (var i = 0; i < 100; i++) {
          if (apiService.isAuthenticated) {
            Log.info(
                'current user does not have a sub: ${purchaseDetails.productID}');
            await _verifyPurchase(purchaseDetails);
            break;
          }
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }

    if (purchaseDetails.status == PurchaseStatus.error) {
      await iapConnection.restorePurchases();
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
