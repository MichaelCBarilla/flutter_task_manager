import Cocoa
import FlutterMacOS

class ProcessManager {
    static func getRunningProcesses() -> [[String: Any]] {
        var processes: [[String: Any]] = []
        
        // Get all running tasks
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            // Skip tasks without a localized name
            guard let appName = app.localizedName else { continue }
            
            var process: [String: Any] = [:]
            process["pid"] = String(app.processIdentifier)
            process["name"] = appName
            
            processes.append(process)
        }
        
        return processes
    }
    
    static func terminateProcess(pid: Int32) -> Bool {
        // Find the application with the given PID
        let runningApps = NSWorkspace.shared.runningApplications
        
        for app in runningApps {
            if app.processIdentifier == pid {
                return app.terminate()
            }
        }
        
        return false
    }
}