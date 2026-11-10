import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:twonly/core/bridge/memory_importer.dart';
import 'package:twonly/locator.dart';
import 'package:twonly/src/providers/purchases.provider.dart';
import 'package:twonly/src/services/memories/memory_importer.service.dart';
import 'package:twonly/src/services/subscription.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/elements/my_card.element.dart';
import 'package:twonly/src/visual/views/settings/backup/memories_backup_detail.view.dart';

/// Shown after the in-app camera or the system camera opened a memories
/// importer code. Nothing is claimed until "Connect"; leaving this screen in
/// any other way is a cancel.
///
/// "Connect" stays disabled for ten seconds while the screen is visible. The
/// countdown restarts whenever the app goes to the background, so the screen
/// has been on display for the full time. It stops a reflexive tap, not a
/// user who has been talked into it, which is why the warning names the
/// lures.
///
/// Imported memories land in the Memories Backup, so connecting needs a paid
/// plan and the backup turned on. Until both hold, the screen says which one
/// is missing and offers to fix it instead of "Connect"; the countdown starts
/// over once nothing is missing any more.
class ConnectImporterView extends StatefulWidget {
  const ConnectImporterView({required this.link, super.key});

  final String link;

  static const countdownSeconds = 10;

  @override
  State<ConnectImporterView> createState() => _ConnectImporterViewState();
}

enum _Stage { reading, connecting, connected }

/// What has to change before an importer can be connected.
enum _Missing { plan, backup }

class _ConnectImporterViewState extends State<ConnectImporterView>
    with WidgetsBindingObserver {
  int _remaining = ConnectImporterView.countdownSeconds;
  Timer? _timer;
  _Stage _stage = _Stage.reading;
  String? _error;
  late final PurchasesProvider _purchases;
  StreamSubscription<void>? _userSub;
  _Missing? _missing;
  bool _fixing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _purchases = Provider.of<PurchasesProvider>(context, listen: false)
      ..addListener(_onRequirementsChanged);
    _userSub = userService.onUserUpdated.listen(
      (_) => _onRequirementsChanged(),
    );
    _missing = _currentlyMissing();
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _purchases.removeListener(_onRequirementsChanged);
    unawaited(_userSub?.cancel());
    _timer?.cancel();
    super.dispose();
  }

  _Missing? _currentlyMissing() {
    if (_purchases.plan == SubscriptionPlan.Free) return _Missing.plan;
    if (!userService.currentUser.isCloudBackupEnabled) return _Missing.backup;
    return null;
  }

  void _onRequirementsChanged() {
    if (!mounted) return;
    final missing = _currentlyMissing();
    if (missing == _missing) return;
    final nowMet = missing == null;
    setState(() => _missing = missing);
    // "Connect" only appears now, so the warning gets its full time again.
    if (nowMet) _startCountdown();
  }

  /// Opens the subscription page on the free plan, turns the Memories Backup
  /// on otherwise.
  Future<void> _fixMissing() async {
    if (_fixing) return;
    setState(() => _fixing = true);
    try {
      await openMemoriesBackup(context);
    } finally {
      if (mounted) setState(() => _fixing = false);
      _onRequirementsChanged();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _startCountdown();
    } else {
      _timer?.cancel();
      if (mounted) {
        setState(() => _remaining = ConnectImporterView.countdownSeconds);
      }
    }
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _remaining = ConnectImporterView.countdownSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _remaining--);
      if (_remaining <= 0) timer.cancel();
    });
  }

  Future<void> _connect() async {
    setState(() {
      _stage = _Stage.connecting;
      _error = null;
    });
    try {
      await RustMemoryImporter.claim(link: widget.link);
      unawaited(MemoryImporterService.reconcileSoon());
      if (mounted) setState(() => _stage = _Stage.connected);
    } catch (error) {
      Log.warn('importer claim failed: $error');
      if (!mounted) return;
      setState(() {
        _stage = _Stage.reading;
        _error = MemoryImporterService.claimErrorText(context, error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_stage == _Stage.connected) {
      return Scaffold(
        appBar: AppBar(title: Text(context.lang.memoryImporterConnectedTitle)),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(
                    'assets/animations/success.lottie',
                    repeat: false,
                    height: 120,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    context.lang.memoryImporterConnected,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  MyButton(
                    key: const Key('importer-connected-done'),
                    variant: MyButtonVariant.primaryMiddle,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(context.lang.memoryImporterConnectedDone),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final missing = _missing;
    final canConnect =
        missing == null && _remaining <= 0 && _stage == _Stage.reading;
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.memoryImporterConnectTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            if (missing != null) ...[
              MyCard(
                key: const Key('importer-missing'),
                icon: missing == _Missing.plan
                    ? Icons.workspace_premium_rounded
                    : Icons.cloud_off_rounded,
                accentColor: theme.colorScheme.error,
                title: missing == _Missing.plan
                    ? context.lang.memoryImporterRequiresPlanTitle
                    : context.lang.memoryImporterRequiresBackupTitle,
                subtitle: missing == _Missing.plan
                    ? context.lang.memoryImporterRequiresPlan
                    : context.lang.memoryImporterRequiresBackup,
              ),
              const SizedBox(height: 20),
            ],
            Text(
              context.lang.memoryImporterConnectBody,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.lang.memoryImporterConnectWarning(
                  MemoryImporterService.importerOrigin,
                ),
                style: TextStyle(
                  color: theme.colorScheme.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
            const SizedBox(height: 32),
            if (missing != null)
              MyButton(
                key: const Key('importer-fix-missing'),
                onPressed: _fixing ? null : _fixMissing,
                child: Text(
                  missing == _Missing.plan
                      ? context.lang.memoryImporterUpgrade
                      : context.lang.memoryImporterEnableBackup,
                ),
              )
            else
              MyButton(
                key: const Key('importer-connect'),
                onPressed: canConnect ? _connect : null,
                child: _stage == _Stage.connecting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator.adaptive(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        _remaining > 0
                            ? context.lang.memoryImporterConnectIn(_remaining)
                            : context.lang.memoryImporterConnect,
                      ),
              ),
            const SizedBox(height: 12),
            MyButton(
              key: const Key('importer-cancel'),
              variant: MyButtonVariant.secondary,
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.lang.cancel),
            ),
          ],
        ),
      ),
    );
  }
}
