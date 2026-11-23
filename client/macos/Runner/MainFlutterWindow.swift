import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  /// Set from Dart (`io.lab517.noo/minimize`, `setIntercept`): while true, a
  /// minimize — the yellow button, Cmd+M, Window → Minimize — is not carried
  /// out but reported to Dart as `minimizeRequested`, which turns the window
  /// into the mini tracker instead. Deciding before the window moves is what
  /// keeps it from flying into the Dock and straight back out.
  private var interceptMinimize = false
  private var minimizeChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "io.lab517.noo/minimize",
      binaryMessenger: flutterViewController.engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      switch call.method {
      case "setIntercept":
        self.interceptMinimize = (call.arguments as? Bool) ?? false
        result(nil)
      case "minimize":
        // The real thing, past the intercept.
        self.miniaturizeNow()
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    minimizeChannel = channel

    super.awakeFromNib()
  }

  private func miniaturizeNow() {
    super.miniaturize(nil)
  }

  // performMiniaturize (the button, the menu item) ends up here, and so does
  // window_manager's minimize.
  override func miniaturize(_ sender: Any?) {
    if interceptMinimize, let channel = minimizeChannel {
      channel.invokeMethod("minimizeRequested", arguments: nil)
      return
    }
    super.miniaturize(sender)
  }
}
