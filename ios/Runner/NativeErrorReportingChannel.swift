import Flutter

enum NativeErrorReportingChannel {
  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TwonlyErrorReporting") else { return }
    let channel = FlutterMethodChannel(
      name: "eu.twonly/error_reporting", binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "setEnabled" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let enabled = call.arguments as? Bool else {
        result(FlutterError(code: "invalid_consent", message: "Expected a boolean", details: nil))
        return
      }
      do {
        try NativeErrorReporting.setEnabled(enabled)
        result(nil)
      } catch {
        result(FlutterError(code: "consent_failed", message: "Could not save error reporting preference", details: nil))
      }
    }
  }
}
