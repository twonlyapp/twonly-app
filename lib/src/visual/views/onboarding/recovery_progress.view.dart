import 'dart:async';

import 'package:flutter/material.dart';
import 'package:restart_app/restart_app.dart';
import 'package:twonly/src/services/backup.service.dart';
import 'package:twonly/src/utils/log.dart';
import 'package:twonly/src/utils/misc.dart';
import 'package:twonly/src/visual/elements/my_button.element.dart';
import 'package:twonly/src/visual/views/onboarding/components/onboarding_brand.comp.dart';

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

    RecoveryError? error;
    try {
      error = await widget.runRecovery((progress) {
        final index = widget.steps.indexOf(progress);
        if (mounted && index >= 0) {
          setState(() => _currentIndex = index);
        }
      });
    } catch (e, stackTrace) {
      // Without this the step keeps spinning forever and the user is stuck on
      // a screen they cannot leave, with no way to retry.
      Log.error('Recovery failed', error: e, stackTrace: stackTrace);
      error = RecoveryError.unkownError;
    }
    if (!mounted) return;

    if (error != null) {
      setState(() => _error = error);
      return;
    }

    setState(() => _isFinishing = true);

    try {
      await Restart.restartApp(
        notificationTitle: context.lang.recoverSuccessTitle,
        notificationBody: context.lang.recoverSuccessBody,
        forceKill: true,
      );
    } catch (e, stackTrace) {
      // The data is restored at this point, only the restart failed. Show the
      // failure so the user knows to reopen the app themselves.
      Log.error(
        'Restart after recovery failed',
        error: e,
        stackTrace: stackTrace,
      );
      if (mounted) setState(() => _error = RecoveryError.unkownError);
    }
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
    switch (status) {
      case _StepStatus.done:
        return Icon(
          Icons.check_circle_rounded,
          color: context.appColor(AppColor.success),
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
        return Icon(
          Icons.error_rounded,
          color: context.color.error,
          size: 24,
        );
      case _StepStatus.pending:
        return Icon(
          Icons.circle_outlined,
          size: 24,
          color: context.color.outlineVariant,
        );
    }
  }

  TextStyle _labelStyle(BuildContext context, _StepStatus status) {
    const base = TextStyle(fontSize: 15, height: 1.3);
    switch (status) {
      case _StepStatus.active:
        return base.copyWith(
          fontWeight: FontWeight.w600,
          color: context.color.onSurface,
        );
      case _StepStatus.error:
        return base.copyWith(
          fontWeight: FontWeight.w600,
          color: context.color.error,
        );
      case _StepStatus.done:
        return base.copyWith(color: context.color.onSurfaceVariant);
      case _StepStatus.pending:
        return base.copyWith(color: context.color.outline);
    }
  }

  Widget _buildStepRow(BuildContext context, int index) {
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
                        ? context
                              .appColor(AppColor.success)
                              .withValues(alpha: 0.4)
                        : context.color.outlineVariant,
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
    final hasFailed = _error != null;

    return PopScope(
      // While the recovery is running the local data is already replaced,
      // so the user should not be able to leave in between.
      canPop: hasFailed,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Stack(
          children: [
            const OnboardingBackgroundGlow(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              // Keeps its space so the page does not jump
                              // when a failure brings the arrow back.
                              child: Visibility.maintain(
                                visible: hasFailed,
                                child: IconButton(
                                  // Lines the arrow up with the text below.
                                  padding: EdgeInsets.zero,
                                  alignment: AlignmentDirectional.centerStart,
                                  icon: const BackButtonIcon(),
                                  tooltip: MaterialLocalizations.of(
                                    context,
                                  ).backButtonTooltip,
                                  onPressed: hasFailed
                                      ? () => Navigator.of(context).pop()
                                      : null,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const SizedBox(height: 24),
                            Text(
                              context.lang.recoverProgressTitle,
                              style: TextStyle(
                                fontSize: 32,
                                height: 1.15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: context.color.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              context.lang.recoverProgressSubtitle,
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.45,
                                color: context.color.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 32),
                            for (var i = 0; i < _stepCount; i++)
                              _buildStepRow(context, i),
                            if (hasFailed) ...[
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: context.color.errorContainer,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline_rounded,
                                      color: context.color.onErrorContainer,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        _error!.toLocalizedString(context),
                                        style: TextStyle(
                                          fontSize: 15,
                                          height: 1.4,
                                          fontWeight: FontWeight.w500,
                                          color: context.color.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              MyButton(
                                onPressed: _startRecovery,
                                child: Text(context.lang.tryRestoreAgain),
                              ),
                            ],
                            const Spacer(flex: 3),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
