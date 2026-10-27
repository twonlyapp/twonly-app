import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/constants/subscription.keys.dart';
import 'package:twonly/src/model/purchasable_product.model.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/api/api.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/services/user.service.dart';

import '../mocks/user_config.dart';

class _PurchaseApi implements RustLibApi {
  ApiConnectionState state = ApiConnectionState.authenticated;
  Completer<ApiConnectionState>? initialState;
  final verifications = <String>[];
  Future<void> Function()? verify;
  int forcedChecks = 0;
  int stateReads = 0;

  @override
  Future<ApiConnectionState> crateBridgeApiRustApiConnectionState() async {
    stateReads++;
    return initialState == null ? state : await initialState!.future;
  }

  @override
  Future<void> crateBridgeApiRustApiIpaPurchase({
    required String productId,
    required String source,
    required String verificationData,
  }) async {
    verifications.add(verificationData);
    await verify?.call();
  }

  @override
  Future<void> crateBridgeApiRustApiForceIpaCheck() async => forcedChecks++;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ApiEvents implements ApiService {
  _ApiEvents(this.events);

  @override
  final Stream<ApiEvent> events;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Store implements InAppPurchase {
  final updates = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  final completed = <PurchaseDetails>[];
  int restores = 0;
  int buys = 0;
  bool buyStarts = true;
  bool failBuy = false;
  int completionFailures = 0;
  Completer<void>? restoring;

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => updates.stream;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: [], notFoundIDs: []);

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
    await restoring?.future;
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    buys++;
    if (failBuy) throw StateError('store unavailable');
    return buyStarts;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (completionFailures > 0) {
      completionFailures--;
      throw StateError('could not finish transaction');
    }
    completed.add(purchase);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final api = _PurchaseApi();
  late _Store store;
  late StreamController<ApiEvent> events;
  late PurchasesProvider provider;

  setUpAll(() => RustLib.initMock(api: api));
  tearDownAll(RustLib.dispose);

  setUp(() async {
    await locator.reset();
    api
      ..state = ApiConnectionState.authenticated
      ..initialState = null
      ..verifications.clear()
      ..verify = null
      ..forcedChecks = 0
      ..stateReads = 0;
    store = _Store();
    IAPConnection.instance = store;
    events = StreamController<ApiEvent>.broadcast(sync: true);
    locator
      ..registerSingleton<ApiService>(_ApiEvents(events.stream))
      ..registerSingleton<UserService>(UserService());
    userService
      ..isUserCreated = true
      ..currentUser = testUserConfig(
        userId: 1,
        username: 'test',
        displayName: 'Test',
        subscriptionPlan: 'Free',
        currentSetupPage: null,
        appVersion: 1,
      );
  });

  tearDown(() async {
    await store.updates.close();
    await events.close();
    await locator.reset();
  });

  Future<void> start(
    WidgetTester tester, {
    String plan = 'Free',
    bool autoDispose = true,
  }) async {
    userService.currentUser.subscriptionPlan = plan;
    provider = withClock(
      Clock(tester.binding.clock.now),
      PurchasesProvider.new,
    );
    if (autoDispose) addTearDown(provider.dispose);
    await tester.pump();
  }

  void connection(ApiConnectionState state) {
    api.state = state;
    events.add(
      ApiEvent(kind: ApiEventKind.connectionStateChanged, state: state),
    );
  }

  PurchaseDetails purchase({
    String receipt = 'receipt',
    String id = 'transaction',
    String date = '1000',
    PurchaseStatus status = PurchaseStatus.purchased,
  }) => PurchaseDetails(
    productID: SubscriptionKeys.proMonthly,
    purchaseID: id,
    transactionDate: date,
    verificationData: PurchaseVerificationData(
      localVerificationData: '',
      serverVerificationData: receipt,
      source: 'app_store',
    ),
    status: status,
  )..pendingCompletePurchase = true;

  PurchasableProduct product() => PurchasableProduct(
    ProductDetails(
      id: SubscriptionKeys.proMonthly,
      title: 'Pro',
      description: '',
      price: '1',
      rawPrice: 1,
      currencyCode: 'EUR',
    ),
  );

  testWidgets('serializes batches and deduplicates the same transaction', (
    tester,
  ) async {
    final verifying = Completer<void>();
    api.verify = () => verifying.future;
    await start(tester);
    store.updates.add([purchase()]);
    await tester.pump();
    store.updates.add([purchase()]);
    store.updates.add([purchase(receipt: 'second', id: 'second')]);
    await tester.pump();
    expect(api.verifications, ['receipt']);
    verifying.complete();
    await tester.pump();
    expect(api.verifications, ['receipt', 'second']);
    expect(store.completed, hasLength(2));
  });

  testWidgets('allows renewals that reuse the purchase ID and token', (
    tester,
  ) async {
    await start(tester);
    store.updates.add([purchase(), purchase(date: '2000')]);
    await tester.pump();
    expect(api.verifications, hasLength(2));
  });

  testWidgets('verifies a user-triggered restore once and clears intent', (
    tester,
  ) async {
    await start(tester);
    await provider.buy(product());
    store.updates.add([purchase(status: PurchaseStatus.restored)]);
    await tester.pump();
    expect(api.verifications, ['receipt']);
    provider.updatePlan(SubscriptionPlan.Pro);
    store.updates.add([
      purchase(receipt: 'other', id: 'other', status: PurchaseStatus.restored),
    ]);
    await tester.pump();
    expect(api.verifications, ['receipt']);
  });

  testWidgets('waits for authentication and rechecks the plan', (tester) async {
    api.state = ApiConnectionState.connecting;
    await start(tester);
    store.updates.add([purchase(status: PurchaseStatus.restored)]);
    await tester.pump(const Duration(seconds: 120));
    expect(api.verifications, isEmpty);
    expect(api.stateReads, 1);
    userService.currentUser.subscriptionPlan = 'Pro';
    connection(ApiConnectionState.authenticated);
    await tester.pump();
    expect(api.verifications, isEmpty);
    expect(store.completed, hasLength(1));
  });

  testWidgets('registers missing entitlement on authentication', (
    tester,
  ) async {
    api.state = ApiConnectionState.connecting;
    await start(tester);
    store.updates.add([purchase(status: PurchaseStatus.restored)]);
    await tester.pump();
    expect(store.completed, isEmpty);
    connection(ApiConnectionState.authenticated);
    await tester.pump();
    expect(api.verifications, ['receipt']);
    expect(store.completed, hasLength(1));
  });

  testWidgets('late state query cannot override authentication event', (
    tester,
  ) async {
    api.initialState = Completer<ApiConnectionState>();
    await start(tester);
    connection(ApiConnectionState.authenticated);
    api.initialState!.complete(ApiConnectionState.stopped);
    store.updates.add([purchase()]);
    await tester.pump();
    expect(api.verifications, ['receipt']);
  });

  testWidgets('retries transient failure before completing the purchase', (
    tester,
  ) async {
    api.verify = () async => throw StateError('API error code 500');
    await start(tester);
    store.updates.add([purchase()]);
    await tester.pump();
    expect(store.completed, isEmpty);
    store.updates.add([purchase()]);
    connection(ApiConnectionState.authenticated);
    await tester.pump(const Duration(seconds: 29));
    expect(api.verifications, hasLength(1));
    api.verify = null;
    await tester.pump(const Duration(seconds: 1));
    expect(api.verifications, hasLength(2));
    expect(store.completed, hasLength(1));
  });

  testWidgets('limits retries despite duplicate events and reconnects', (
    tester,
  ) async {
    api.verify = () async => throw StateError('API error code 500');
    await start(tester);
    store.updates.add([purchase()]);
    await tester.pump();
    await tester.pump(const Duration(seconds: 30));
    await tester.pump(const Duration(seconds: 30));
    store.updates.add([purchase()]);
    connection(ApiConnectionState.authenticated);
    await tester.pump(const Duration(minutes: 10));
    expect(api.verifications, hasLength(3));
    expect(store.completed, isEmpty);
    expect(store.restores, 1);
  });

  testWidgets('finishes permanently rejected purchases without retrying', (
    tester,
  ) async {
    api.verify = () async => throw StateError('API error code 1034');
    await start(tester);
    store.updates.add([purchase(), purchase()]);
    await tester.pump(const Duration(minutes: 2));
    expect(api.verifications, hasLength(1));
    expect(store.completed, hasLength(1));
  });

  testWidgets('retries store completion without repeating verification', (
    tester,
  ) async {
    store.completionFailures = 1;
    await start(tester);
    store.updates.add([purchase()]);
    await tester.pump();
    expect(store.completed, isEmpty);
    await tester.pump(const Duration(seconds: 30));
    expect(api.verifications, hasLength(1));
    expect(store.completed, hasLength(1));
  });

  testWidgets('purchase errors do not trigger restore and release buy lock', (
    tester,
  ) async {
    await start(tester, plan: 'Pro');
    await provider.buy(product());
    store.updates.add([purchase(status: PurchaseStatus.error)]);
    await tester.pump();
    await provider.buy(product());
    expect(store.buys, 2);
    expect(store.restores, 1);
    expect(api.verifications, isEmpty);
  });

  testWidgets('cancellation clears intent and allows another purchase', (
    tester,
  ) async {
    await start(tester, plan: 'Pro');
    await provider.buy(product());
    store.updates.add([purchase(status: PurchaseStatus.canceled)]);
    await tester.pump();
    store.updates.add([purchase(status: PurchaseStatus.restored)]);
    await tester.pump();
    expect(api.verifications, isEmpty);
    await provider.buy(product());
    expect(store.buys, 2);
  });

  testWidgets('failed purchase launch clears intent and allows retry', (
    tester,
  ) async {
    await start(tester, plan: 'Pro');
    store.failBuy = true;
    await expectLater(provider.buy(product()), throwsStateError);
    store
      ..failBuy = false
      ..buyStarts = false;
    await provider.buy(product());
    store.buyStarts = true;
    await provider.buy(product());
    expect(store.buys, 3);
  });

  testWidgets('routine startup never forces backend store verification', (
    tester,
  ) async {
    await start(tester, plan: 'Pro');
    await tester.pump(const Duration(seconds: 10));
    expect(api.forcedChecks, 0);
    expect(store.restores, 1);
  });

  testWidgets('coalesces concurrent store loads', (tester) async {
    store.restoring = Completer<void>();
    await start(tester);
    final first = provider.loadPurchases();
    final second = provider.loadPurchases();
    expect(identical(first, second), isTrue);
    expect(store.restores, 1);
    store.restoring!.complete();
    await tester.pump();
  });

  testWidgets('pauses retry while offline and resumes after authentication', (
    tester,
  ) async {
    api.verify = () async => throw StateError('API error code 500');
    await start(tester);
    store.updates.add([purchase()]);
    await tester.pump();
    connection(ApiConnectionState.stopped);
    await tester.pump(const Duration(minutes: 5));
    expect(api.verifications, hasLength(1));
    expect(store.completed, isEmpty);
    api.verify = null;
    connection(ApiConnectionState.authenticated);
    await tester.pump();
    expect(api.verifications, hasLength(2));
    expect(store.completed, hasLength(1));
  });

  testWidgets('completion failure does not block later purchases in a batch', (
    tester,
  ) async {
    store.completionFailures = 1;
    await start(tester);
    store.updates.add([purchase(), purchase(receipt: 'second', id: 'second')]);
    await tester.pump();
    expect(api.verifications, ['receipt', 'second']);
    expect(store.completed.single.purchaseID, 'second');
    await tester.pump(const Duration(seconds: 30));
    expect(api.verifications, hasLength(2));
    expect(store.completed, hasLength(2));
  });

  testWidgets('later duplicate can finish a previously verified restore', (
    tester,
  ) async {
    await start(tester);
    store.updates.add([
      purchase(status: PurchaseStatus.restored)
        ..pendingCompletePurchase = false,
    ]);
    await tester.pump();
    expect(api.verifications, ['receipt']);
    expect(store.completed, isEmpty);
    store.updates.add([purchase()]);
    await tester.pump();
    expect(api.verifications, ['receipt']);
    expect(store.completed, hasLength(1));
  });

  testWidgets('restored duplicate preserves an unfinished purchased event', (
    tester,
  ) async {
    api.state = ApiConnectionState.connecting;
    await start(tester);
    final unfinished = purchase();
    store.updates.add([unfinished]);
    store.updates.add([
      purchase(status: PurchaseStatus.restored)
        ..pendingCompletePurchase = false,
    ]);
    await tester.pump();
    expect(api.verifications, isEmpty);
    connection(ApiConnectionState.authenticated);
    await tester.pump();
    expect(api.verifications, ['receipt']);
    expect(store.completed, [unfinished]);
  });

  testWidgets('disposal cancels retries and ignores queued purchase events', (
    tester,
  ) async {
    api.verify = () async => throw StateError('API error code 500');
    await start(tester, autoDispose: false);
    store.updates.add([purchase()]);
    await tester.pump();
    store.updates.add([purchase(receipt: 'later', id: 'later')]);
    provider.dispose();
    await tester.pump(const Duration(minutes: 2));
    expect(api.verifications, ['receipt']);
    expect(store.completed, isEmpty);
  });
}
