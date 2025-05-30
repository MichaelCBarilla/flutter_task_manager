import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    
    // Register method channel
    let controller : FlutterViewController = flutterViewController
    let processChannel = FlutterMethodChannel(
      name: "com.example.flutterTaskManager/process",
      binaryMessenger: controller.engine.binaryMessenger
    )
    
    processChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "getProcesses":
        let processes = ProcessManager.getRunningProcesses()
        result(processes)
      case "killProcess":
        if let args = call.arguments as? [String: Any],
           let pidString = args["pid"] as? String,
           let pid = Int32(pidString) {
          let success = ProcessManager.terminateProcess(pid: pid)
          result(success)
        } else {
          result(FlutterError(code: "INVALID_ARGUMENT",
                             message: "Invalid PID",
                             details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}