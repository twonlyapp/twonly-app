// UI tests inherit the generated native API and override only transport or
// platform operations. Database behavior is always provided by Rust.
import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
// FRB's generated implementation requires these unexported initialization types.
import 'package:flutter_rust_bridge/src/generalized_frb_rust_binding/generalized_frb_rust_binding.dart';
import 'package:flutter_rust_bridge/src/main_components/port_manager.dart';
import 'package:twonly/core/bridge.dart' as bridge;
import 'package:twonly/core/bridge/api.dart';
import 'package:twonly/core/frb_generated.dart';
import 'package:twonly/core/frb_generated.io.dart';

final _runtime = _NativeRuntime();
Future<void>? _initialization;

Future<void> initializeNativeDatabase({RustLibApi? api}) =>
    _initialization ??= _initialize(api);

Future<void> _initialize(RustLibApi? api) async {
  if (RustLib.instance.initialized) return;
  await RustLib.init(
    api: api ?? NativeTestApi(),
    externalLibrary: _runtime.library,
  );
  final directory = Directory.systemTemp.createTempSync('twonly-native-ui-');
  await bridge.initializeTwonlyStandalone(
    config: bridge.InitConfig(
      databaseDir: directory.path,
      dataDir: directory.path,
    ),
  );
  await RustApi.close();
  // The Rust context owns these files until the test process exits.
}

class _NativeRuntime {
  _NativeRuntime() {
    final suffix = Platform.isMacOS
        ? 'dylib'
        : Platform.isWindows
        ? 'dll'
        : 'so';
    final prefix = Platform.isWindows ? '' : 'lib';
    final file = File('rust/target/debug/${prefix}rust_lib_twonly.$suffix');
    if (!file.existsSync()) {
      throw StateError(
        'Build the host Rust library first: cargo build --manifest-path rust/Cargo.toml --lib',
      );
    }
    library = ExternalLibrary.open(file.absolute.path);
    handler = BaseHandler();
    binding = GeneralizedFrbRustBinding(library);
    portManager = PortManager(binding, handler);
    wire = RustLibWire.fromExternalLibrary(library);
  }
  late final ExternalLibrary library;
  late final BaseHandler handler;
  late final GeneralizedFrbRustBinding binding;
  late final PortManager portManager;
  late final RustLibWire wire;
}

class NativeTestApi extends RustLibApiImpl {
  NativeTestApi()
    : super(
        handler: _runtime.handler,
        wire: _runtime.wire,
        generalizedFrbRustBinding: _runtime.binding,
        portManager: _runtime.portManager,
      );
}
