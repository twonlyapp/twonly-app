import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/link_logo_animation.dart';

/// Runs the actual recovery and reports every step it enters.
typedef RecoveryRunner =
    Future<RecoveryError?> Function(void Function(RecoveryProgress) onProgress);

enum _StepStatus { pending, active, done, error }

/// Shows the user what the recovery is currently doing. Used by both the
/// password based and the passwordless recovery. On success the app is
/// restarted so the restored key manager and archive database are loaded.
class RecoveryProgressView extends StatefulWidget {
  const RecoveryProgressView({
    required this.steps,
    required this.runRecovery,
    this.username,
    super.key,
  });

  /// The steps the recovery will report, in the order they will happen.
  final List<RecoveryProgress> steps;
  final RecoveryRunner runRecovery;

  /// Username or display name of the account being restored.
  final String? username;

  @override
  State<RecoveryProgressView> createState() => _RecoveryProgressViewState();
}

class _RecoveryProgressViewState extends State<RecoveryProgressView> {
  /// Index into [RecoveryProgressView.steps], -1 until the first step starts.
  int _currentIndex = -1;
  bool _isFinishing = false;
  RecoveryError? _error;

  /// The last step is a UI only step shown while the app restarts.
  int get _stepCount => widget.steps.length + 1;

  bool get _hasUsername =>
      widget.username != null && widget.username!.isNotEmpty;

  /// The username belongs under the account check, or under the first step
  /// when the recovery does not look up the account at all.
  int get _usernameStepIndex {
    final index = widget.steps.indexOf(RecoveryProgress.resolvingAccount);
    return index >= 0 ? index : 0;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_startRecovery());
  }

  Future<void> _startRecovery() async {
    setState(() {
      _currentIndex = -1;
      _isFinishing = false;
      _error = null;
    });

    final error = await widget.runRecovery((progress) {
      final index = widget.steps.indexOf(progress);
      if (mounted && index >= 0) {
        setState(() => _currentIndex = index);
      }
    });
    if (!mounted) return;

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _isFinishing = true);

    await Restart.restartApp(
      notificationTitle: context.lang.recoverSuccessTitle,
      notificationBody: context.lang.recoverSuccessBody,
      forceKill: true,
    );
  }

  _StepStatus _statusFor(int index) {
    if (_error != null) {
      if (index < _currentIndex) return _StepStatus.done;
      if (index == _currentIndex) return _StepStatus.error;
      return _StepStatus.pending;
    }

    if (_isFinishing) {
      return index < widget.steps.length
          ? _StepStatus.done
          : _StepStatus.active;
    }

    if (index < _currentIndex) return _StepStatus.done;
    if (index == _currentIndex) return _StepStatus.active;
    return _StepStatus.pending;
  }

  String _labelFor(BuildContext context, int index) {
    if (index >= widget.steps.length) {
      return context.lang.recoverProgressFinishing;
    }
    switch (widget.steps[index]) {
      case RecoveryProgress.resolvingAccount:
        return context.lang.recoverProgressResolvingAccount;
      case RecoveryProgress.restoringIdentity:
        return context.lang.recoverProgressRestoringIdentity;
      case RecoveryProgress.downloadingArchive:
        return context.lang.recoverProgressDownloadingArchive;
      case RecoveryProgress.extractingData:
        return context.lang.recoverProgressExtractingData;
    }
  }

  Widget _buildStatusIcon(BuildContext context, _StepStatus status) {
    final isDark = isDarkMode(context);
    switch (status) {
      case _StepStatus.done:
        return const Icon(
          Icons.check_circle_rounded,
          color: Colors.green,
          size: 24,
        );
      case _StepStatus.active:
        return SizedBox(
          width: 24,
          height: 24,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: context.color.primary,
            ),
          ),
        );
      case _StepStatus.error:
        return const Icon(
          Icons.error_rounded,
          color: Colors.redAccent,
          size: 24,
        );
      case _StepStatus.pending:
        return Icon(
          Icons.circle_outlined,
          size: 24,
          color: isDark ? Colors.white24 : Colors.black26,
        );
    }
  }

  TextStyle _labelStyle(BuildContext context, _StepStatus status) {
    final isDark = isDarkMode(context);
    const base = TextStyle(fontSize: 15, height: 1.3);
    switch (status) {
      case _StepStatus.active:
        return base.copyWith(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        );
      case _StepStatus.error:
        return base.copyWith(
          fontWeight: FontWeight.w600,
          color: Colors.redAccent,
        );
      case _StepStatus.done:
        return base.copyWith(color: isDark ? Colors.white60 : Colors.black54);
      case _StepStatus.pending:
        return base.copyWith(color: isDark ? Colors.white30 : Colors.black38);
    }
  }

  Widget _buildStepRow(BuildContext context, int index) {
    final isDark = isDarkMode(context);
    final isLast = index == _stepCount - 1;
    final status = _statusFor(index);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              _buildStatusIcon(context, status),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: status == _StepStatus.done
                        ? Colors.green.withValues(alpha: 0.4)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _labelFor(context, index),
                    style: _labelStyle(context, status),
                  ),
                  if (index == _usernameStepIndex && _hasUsername) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.username!,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: context.color.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = isDarkMode(context);
    final titleColor = isDark ? Colors.white : Colors.black87;
    final hasFailed = _error != null;

    return PopScope(
      // While the recovery is running the local data is already replaced,
      // so the user should not be able to leave in between.
      canPop: hasFailed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: hasFailed
                          ? () => Navigator.of(context).pop()
                          : null,
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: isDark ? Colors.white70 : Colors.black54,
                      iconSize: 20,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: LinkLogoAnimation(
                      size: 90,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.lang.recoverProgressTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: titleColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.lang.recoverProgressSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  child: Column(
                    children: [
                      for (var i = 0; i < _stepCount; i++)
                        _buildStepRow(context, i),
                    ],
                  ),
                ),
                if (hasFailed) ...[
                  const SizedBox(height: 24),
                  Text(
                    _error!.toLocalizedString(context),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 20),
                  MyButton(
                    onPressed: _startRecovery,
                    child: Text(context.lang.tryRestoreAgain),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
