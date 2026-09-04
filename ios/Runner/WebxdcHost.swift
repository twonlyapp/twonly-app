import Flutter
import UIKit
import UniformTypeIdentifiers
import WebKit

/// The Dart side of the webxdc runtime.
///
/// The webview is a platform view embedded in an ordinary Flutter route, so the
/// app runs inside twonly rather than on a screen of its own. Everything the
/// page asks for is answered by Dart, which asks Rust: nothing here reads a
/// bundle, decides a limit, or trusts a value the page produced.
///
/// Shares its channel name with the Android implementation, so Dart talks to
/// one channel on both platforms.
class WebxdcHostChannel: NSObject {
  private static let channelName = "eu.twonly/webxdc"
  static private(set) var shared: WebxdcHostChannel?

  private var channel: FlutterMethodChannel?

  static func register(with registry: FlutterPluginRegistry) {
    guard let registrar = registry.registrar(forPlugin: "TwonlyWebxdc") else {
      return
    }
    let host = WebxdcHostChannel()
    let channel = FlutterMethodChannel(
      name: channelName,
      binaryMessenger: registrar.messenger()
    )
    host.channel = channel
    channel.setMethodCallHandler { call, result in
      host.handle(call, result: result)
    }
    shared = host

    registrar.register(
      WebxdcViewFactory(),
      withId: WebxdcViewFactory.viewType
    )
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let arguments = call.arguments as? [String: Any] ?? [:]

    switch call.method {
    case "deliver":
      if let instanceId = arguments["instanceId"] as? String,
        let message = arguments["message"] as? String
      {
        WebxdcPlatformView.deliver(instanceId: instanceId, message: message)
      }
      result(nil)

    case "clearOrigin":
      // The update log is only half an app's state; the rest is whatever it put
      // in localStorage or IndexedDB, which only WebKit can delete.
      guard let origin = arguments["origin"] as? String else {
        result(nil)
        return
      }
      let store = WKWebsiteDataStore.default()
      store.fetchDataRecords(ofTypes: WKWebsiteDataStore.allWebsiteDataTypes()) { records in
        let matching = records.filter { $0.displayName.contains(origin) }
        store.removeData(
          ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(), for: matching
        ) {
          result(nil)
        }
      }

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  /// Asks Dart for one file out of the bundle.
  func serve(
    instanceId: String, path: String, completion: @escaping ([String: Any]?) -> Void
  ) {
    guard let channel = channel else {
      completion(nil)
      return
    }
    channel.invokeMethod("serve", arguments: ["instanceId": instanceId, "path": path]) { reply in
      completion(reply as? [String: Any])
    }
  }

  /// Forwards one `webxdc.js` call; the JSON reply goes back to the page.
  func bridge(instanceId: String, message: String, completion: @escaping (String) -> Void) {
    guard let channel = channel else {
      completion("{\"error\":\"unavailable\"}")
      return
    }
    channel.invokeMethod("bridge", arguments: ["instanceId": instanceId, "message": message]) {
      reply in
      completion(reply as? String ?? "{\"error\":\"unavailable\"}")
    }
  }

  /// Hands a link the user tapped to Dart, which shows the whole URL and asks
  /// before anything opens. Fire and forget: the page is not told.
  func openLink(_ url: String) {
    channel?.invokeMethod("openLink", arguments: ["url": url])
  }
}

class WebxdcViewFactory: NSObject, FlutterPlatformViewFactory {
  static let viewType = "eu.twonly/webxdc_webview"

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }

  func create(
    withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?
  ) -> FlutterPlatformView {
    let params = args as? [String: Any] ?? [:]
    return WebxdcPlatformView(
      frame: frame,
      instanceId: params["instanceId"] as? String ?? "",
      origin: params["origin"] as? String ?? ""
    )
  }
}

/// The one WKWebView twonly ever creates, embedded in a Flutter route.
///
/// A webxdc app is third-party code, so this view is built around denying it
/// things:
///
///  - it is served from a custom scheme handled in-process, so every request it
///    makes is answered from the bundle or refused, and nothing reaches the
///    network,
///  - its host is unique per instance, so WebKit's own origin model keeps one
///    app's storage out of reach of every other app,
///  - navigation away from that origin is cancelled, and a link the user taps
///    goes to Dart for confirmation before it reaches Safari,
///  - `webxdc.js` is served, not injected, so it carries the same CSP as the
///    rest of the app and cannot race the page's own scripts.
///
/// Nothing here parses a bundle or decides a limit: the bytes and the headers
/// come from Rust, by way of Dart.
class WebxdcPlatformView: NSObject, FlutterPlatformView {
  /// Handled in-process, so a request can never leave the device.
  ///
  /// It is not `https`, which WebKit will not let an app handle, so pages here
  /// are not a secure context. That is an accepted limitation: webxdc apps do
  /// not require one.
  static let scheme = "twonly-webxdc"

  /// Refuses to read more than this in one import, however many files.
  private static let maxImportBytes = 32 * 1024 * 1024

  private static weak var current: WebxdcPlatformView?

  let instanceId: String
  private let origin: String
  private var webView: WKWebView!

  /// The `importFiles` call waiting on the picker, if one is open.
  private var importCallId: Int?
  private var importExtensions: [String] = []

  init(frame: CGRect, instanceId: String, origin: String) {
    self.instanceId = instanceId
    self.origin = origin
    super.init()

    let configuration = WKWebViewConfiguration()
    configuration.setURLSchemeHandler(
      SchemeHandler(view: self), forURLScheme: WebxdcPlatformView.scheme)
    configuration.userContentController.add(BridgeHandler(view: self), name: "twonlyWebxdc")
    // Nothing plays without the user asking for it, and no page may take over
    // the screen on its own.
    configuration.mediaTypesRequiringUserActionForPlayback = .all
    configuration.allowsInlineMediaPlayback = true
    configuration.allowsPictureInPictureMediaPlayback = false

    let webView = WKWebView(frame: frame, configuration: configuration)
    webView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    webView.navigationDelegate = self
    webView.uiDelegate = self
    webView.allowsBackForwardNavigationGestures = false
    webView.allowsLinkPreview = false
    self.webView = webView

    WebxdcPlatformView.current = self
    webView.load(URLRequest(url: URL(string: "\(originUrl())/index.html")!))
  }

  func view() -> UIView {
    webView
  }

  private func originUrl() -> String {
    "\(WebxdcPlatformView.scheme)://\(origin)"
  }

  static func deliver(instanceId: String, message: String) {
    guard let view = current, view.instanceId == instanceId else { return }
    view.deliverToPage(message)
  }

  func deliverToPage(_ message: String) {
    guard let data = try? JSONSerialization.data(withJSONObject: [message]),
      let quoted = String(data: data, encoding: .utf8)
    else { return }
    // `quoted` is a JSON array of one string; taking element zero hands the page
    // a correctly escaped literal without building one by hand.
    webView.evaluateJavaScript(
      "window.__twonlyWebxdcDeliver(JSON.parse((\(quoted))[0]))", completionHandler: nil)
  }

  fileprivate func isOwnOrigin(_ url: URL?) -> Bool {
    url?.scheme == WebxdcPlatformView.scheme && url?.host == origin
  }

  fileprivate func askHostToServe(
    path: String, completion: @escaping ([String: Any]?) -> Void
  ) {
    guard let host = WebxdcHostChannel.shared else {
      completion(nil)
      return
    }
    host.serve(instanceId: instanceId, path: path, completion: completion)
  }

  fileprivate func askHostToBridge(_ message: String, completion: @escaping (String) -> Void) {
    guard let host = WebxdcHostChannel.shared else {
      completion("{\"error\":\"unavailable\"}")
      return
    }
    host.bridge(instanceId: instanceId, message: message, completion: completion)
  }

  /// The controller a picker can be presented from. A platform view has no
  /// controller of its own, so it borrows the one showing the Flutter route it
  /// is embedded in.
  private func presenter() -> UIViewController? {
    var controller = UIApplication.shared.delegate?.window??.rootViewController
    while let presented = controller?.presentedViewController {
      controller = presented
    }
    return controller
  }

  /// Answers `importFiles` here rather than in Dart: the picker belongs to this
  /// screen, and the bytes the user chose have no reason to travel any further
  /// than the page that asked for them.
  fileprivate func startImport(_ call: [String: Any]) {
    let callId = call["id"] as? Int ?? 0
    guard importCallId == nil else {
      // One picker at a time; a second request while one is open is answered
      // empty rather than queued.
      deliverImportResult(callId: callId, files: [])
      return
    }
    importCallId = callId

    let params = call["params"] as? [String: Any] ?? [:]
    importExtensions = (params["extensions"] as? [String] ?? []).map {
      let lowered = $0.lowercased()
      return lowered.hasPrefix(".") ? String(lowered.dropFirst()) : lowered
    }
    let mimeTypes = params["mimeTypes"] as? [String] ?? []

    var types: [UTType] = mimeTypes.compactMap { UTType(mimeType: $0) }
    types += importExtensions.compactMap { UTType(filenameExtension: $0) }
    if types.isEmpty {
      types = [.item]
    }

    let picker = UIDocumentPickerViewController(forOpeningContentTypes: types, asCopy: true)
    picker.allowsMultipleSelection = params["multiple"] as? Bool ?? false
    picker.delegate = self
    guard let presenter = presenter() else {
      finishImport(urls: [])
      return
    }
    presenter.present(picker, animated: true)
  }

  fileprivate func finishImport(urls: [URL]) {
    guard let callId = importCallId else { return }
    importCallId = nil

    var files: [[String: Any]] = []
    var budget = WebxdcPlatformView.maxImportBytes

    for url in urls {
      let needsScope = url.startAccessingSecurityScopedResource()
      defer { if needsScope { url.stopAccessingSecurityScopedResource() } }

      // Only the file's own name; it must never read as a path.
      let name = url.lastPathComponent
      if !importExtensions.isEmpty
        && !importExtensions.contains(url.pathExtension.lowercased())
      {
        continue
      }
      guard let data = try? Data(contentsOf: url), data.count <= budget else { continue }
      budget -= data.count

      files.append([
        "name": name,
        "type": UTType(filenameExtension: url.pathExtension)?.preferredMIMEType ?? "",
        "base64": data.base64EncodedString(),
      ])
      if budget <= 0 { break }
    }

    deliverImportResult(callId: callId, files: files)
  }

  private func deliverImportResult(callId: Int, files: [[String: Any]]) {
    let reply: [String: Any] = ["id": callId, "result": files]
    guard let data = try? JSONSerialization.data(withJSONObject: reply),
      let json = String(data: data, encoding: .utf8)
    else { return }
    deliverToPage(json)
  }
}

extension WebxdcPlatformView: UIDocumentPickerDelegate {
  func documentPicker(
    _ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]
  ) {
    finishImport(urls: urls)
  }

  /// A cancelled picker resolves with nothing rather than rejecting: the app
  /// asked to import, the user declined, and that is not an error.
  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishImport(urls: [])
  }
}

extension WebxdcPlatformView: WKNavigationDelegate {
  func webView(
    _ webView: WKWebView,
    decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
  ) {
    let url = navigationAction.request.url
    if isOwnOrigin(url) {
      decisionHandler(.allow)
      return
    }
    // A link out of the app. Never followed here: Dart shows the whole URL and
    // says it leaves twonly before anything opens.
    decisionHandler(.cancel)
    if navigationAction.navigationType == .linkActivated, let url = url {
      WebxdcHostChannel.shared?.openLink(url.absoluteString)
    }
  }
}

extension WebxdcPlatformView: WKUIDelegate {
  /// No second window, ever: `target="_blank"` and `window.open` both end here.
  func webView(
    _ webView: WKWebView,
    createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction,
    windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    nil
  }

  /// Camera and microphone, denied without a prompt.
  @available(iOS 15.0, *)
  func webView(
    _ webView: WKWebView,
    requestMediaCapturePermissionFor origin: WKSecurityOrigin,
    initiatedByFrame frame: WKFrameInfo,
    type: WKMediaCaptureType,
    decisionHandler: @escaping (WKPermissionDecision) -> Void
  ) {
    decisionHandler(.deny)
  }
}

/// Answers every request the page makes, or refuses it. There is no path from
/// here to the network.
private class SchemeHandler: NSObject, WKURLSchemeHandler {
  private weak var view: WebxdcPlatformView?

  init(view: WebxdcPlatformView) {
    self.view = view
  }

  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let view = view, view.isOwnOrigin(urlSchemeTask.request.url) else {
      finish(urlSchemeTask, status: 403, mime: "text/plain", headers: [:], body: Data())
      return
    }
    let url = urlSchemeTask.request.url!
    let path = url.path.isEmpty ? "/" : url.path

    view.askHostToServe(path: path) { [weak self] served in
      guard let self = self else { return }
      guard let served = served else {
        self.finish(urlSchemeTask, status: 500, mime: "text/plain", headers: [:], body: Data())
        return
      }

      var headers: [String: String] = [:]
      let names = served["headerNames"] as? [String] ?? []
      let values = served["headerValues"] as? [String] ?? []
      for (index, name) in names.enumerated() where index < values.count {
        headers[name] = values[index]
      }

      let body = (served["body"] as? FlutterStandardTypedData)?.data ?? Data()
      self.finish(
        urlSchemeTask,
        status: served["status"] as? Int ?? 500,
        mime: served["mime"] as? String ?? "application/octet-stream",
        headers: headers,
        body: body
      )
    }
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {}

  private func finish(
    _ task: WKURLSchemeTask, status: Int, mime: String, headers: [String: String], body: Data
  ) {
    var allHeaders = headers
    allHeaders["Content-Type"] = mime
    allHeaders["Content-Length"] = String(body.count)
    guard let url = task.request.url,
      let response = HTTPURLResponse(
        url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: allHeaders)
    else { return }
    task.didReceive(response)
    task.didReceive(body)
    task.didFinish()
  }
}

/// The single entry point from the page into twonly.
private class BridgeHandler: NSObject, WKScriptMessageHandler {
  private weak var view: WebxdcPlatformView?

  init(view: WebxdcPlatformView) {
    self.view = view
  }

  func userContentController(
    _ userContentController: WKUserContentController, didReceive message: WKScriptMessage
  ) {
    guard let view = view, let body = message.body as? String else { return }

    if let data = body.data(using: .utf8),
      let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
      parsed["method"] as? String == "importFiles"
    {
      view.startImport(parsed)
      return
    }

    // The instance is the one this view was created for. A page cannot name a
    // different one, whatever it puts in the message.
    view.askHostToBridge(body) { reply in
      view.deliverToPage(reply)
    }
  }
}
