import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:twonly/core/bridge/database.dart';
import 'package:twonly/core/bridge/performance.dart' as rust_performance;
import 'package:twonly/globals.dart';
import 'package:twonly/locator.dart';

/// Operation names are fixed so routes, message IDs and media paths cannot
/// accidentally become performance labels.
enum PerformanceOperation {
  chatListLoad('twonly.chat_list.load', 'ui.load'),
  avatarResolve('twonly.avatar.resolve', 'bridge.call');

  const PerformanceOperation(this.label, this.operation);
  final String label;
  final String operation;
}

class PerformanceTracking {
  static final Object _parentKey = Object();
  static final Set<PerformanceTrace> _active = {};
  static bool _enabled = false;
  static int _generation = 0;

  static bool get enabled {
    if (!_enabled || !AppState.allowErrorTrackingViaSentry) return false;
    try {
      return userService.currentUser.allowErrorTrackingViaSentry &&
          rust_performance.isEnabled();
    } catch (_) {
      return false;
    }
  }

  /// Called only with the existing user-config Sentry permission. Revocation
  /// ends active collectors and invalidates traces across later re-enabling.
  static void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;
    _generation++;
    if (!enabled) {
      for (final trace in _active.toList()) {
        unawaited(trace.finish(status: const SpanStatus.cancelled()));
      }
    }
  }

  static PerformanceTrace? start(PerformanceOperation operation) {
    if (!enabled) return null;
    final parent = Zone.current[_parentKey] as PerformanceTrace?;
    final span =
        parent != null && parent._generation == _generation && !parent._finished
        ? parent._span.startChild(
            operation.operation,
            description: operation.label,
          )
        : Sentry.startTransaction(
            operation.label,
            operation.operation,
            bindToScope: false,
          );
    final trace = PerformanceTrace._(span, _generation);
    span.setTag('telemetry_generation', '$_generation');
    _active.add(trace);
    return trace;
  }

  static T withParent<T>(PerformanceTrace? parent, T Function() action) =>
      parent == null
      ? action()
      : runZoned(action, zoneValues: {_parentKey: parent});

  static void attachToWatch(DatabaseWatch control) {
    if (!enabled) return;
    final parent = Zone.current[_parentKey] as PerformanceTrace?;
    if (parent == null ||
        parent._finished ||
        parent._generation != _generation) {
      return;
    }
    try {
      control.setTraceContext(context: parent._span.toSentryTrace().value);
    } catch (_) {
      // Telemetry must not prevent a database watch from starting.
    }
  }

  static Future<String?> resolveAvatar(int contactId) {
    if (!enabled) return RustApi.ensureAvatarPng(contactId: contactId);
    return measure(PerformanceOperation.avatarResolve, () {
      final parent = Zone.current[_parentKey] as PerformanceTrace?;
      return rust_performance.resolveAvatar(
        contactId: contactId,
        traceContext: parent?._span.toSentryTrace().value,
      );
    });
  }

  static Future<T> measure<T>(
    PerformanceOperation operation,
    Future<T> Function() action,
  ) async {
    final trace = start(operation);
    if (trace == null) return action();
    try {
      final result = await withParent(trace, action);
      await trace.finish();
      return result;
    } catch (_) {
      await trace.finish(status: const SpanStatus.internalError());
      rethrow;
    }
  }

  /// Export only explicitly instrumented transactions from the current opt-in.
  /// Auto-generated route names and inherited error breadcrumbs are excluded.
  static SentryTransaction? beforeSend(
    SentryTransaction transaction,
    Hint hint,
  ) {
    if (!enabled ||
        transaction.tags?['telemetry_generation'] != '$_generation') {
      return null;
    }
    if (!PerformanceOperation.values.any(
      (operation) => operation.label == transaction.transaction,
    )) {
      return null;
    }
    transaction
      ..tags = {'component': 'flutter'}
      ..user = null
      ..request = null;
    transaction.breadcrumbs?.clear();
    // The SDK still serializes inherited scope data through this legacy field.
    // ignore: deprecated_member_use
    transaction.extra?.clear();
    transaction.contexts.trace?.data?.removeWhere(
      (_, value) => value is! num && value is! bool,
    );
    // Only our numeric measurements belong on performance events.
    transaction.contexts.removeWhere(
      (key, _) => !{'trace', 'device', 'os', 'app'}.contains(key),
    );
    transaction.spans.removeWhere(
      (span) => !PerformanceOperation.values.any(
        (operation) => operation.label == span.context.description,
      ),
    );
    for (final span in transaction.spans) {
      span.data.removeWhere((_, value) => value is! num && value is! bool);
      span.tags.clear();
    }
    return transaction;
  }
}

class PerformanceTrace {
  PerformanceTrace._(this._span, this._generation);
  final ISentrySpan _span;
  final int _generation;
  bool _finished = false;

  Future<void> finish({SpanStatus status = const SpanStatus.ok()}) async {
    if (_finished) return;
    _finished = true;
    PerformanceTracking._active.remove(this);
    try {
      await _span.finish(status: status);
    } catch (_) {
      // Performance transport failures must not affect application behavior.
    }
  }
}
