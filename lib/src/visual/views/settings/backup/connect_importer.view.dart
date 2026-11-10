import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:twonly/core/bridge/memory_importer.dart';
import 'package:twonly/src/services/memories/memory_importer.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';

/// Shown after the in-app camera or the system camera opened a memories
/// importer code. Nothing is claimed until "Connect"; leaving this screen in
/// any other way is a cancel.
///
/// "Connect" stays disabled for ten seconds while the screen is visible. The
/// countdown restarts whenever the app goes to the background, so the screen
/// has been on display for the full time. It stops a reflexive tap, not a
/// user who has been talked into it, which is why the warning names the
/// lures.
class ConnectImporterView extends StatefulWidget {
  const ConnectImporterView({required this.link, super.key});

  final String link;

  static const countdownSeconds = 10;

  @override
  State<ConnectImporterView> createState() => _ConnectImporterViewState();
}

enum _Stage { reading, connecting, connected }

class _ConnectImporterViewState extends State<ConnectImporterView>
    with WidgetsBindingObserver {
  int _remaining = ConnectImporterView.countdownSeconds;
  Timer? _timer;
  _Stage _stage = _Stage.reading;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
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

    final canConnect = _remaining <= 0 && _stage == _Stage.reading;
    return Scaffold(
      appBar: AppBar(title: Text(context.lang.memoryImporterConnectTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
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
            MyButton(
              key: const Key('importer-connect'),
              onPressed: canConnect ? _connect : null,
              child: _stage == _Stage.connecting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
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
