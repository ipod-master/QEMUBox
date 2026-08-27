import Foundation

class QEMUWrapper {
    private var qemuProcess: Process?
    private let fileManager = FileManager.default
    
    // MARK: - Launch QEMU
    func launchQEMU(for vm: VirtualMachine) throws {
        let qemuPath = getQEMUPath()
        
        guard fileManager.fileExists(atPath: qemuPath) else {
            throw QEMUError.qemuNotFound
        }
        
        qemuProcess = Process()
        qemuProcess?.executableURL = URL(fileURLWithPath: qemuPath)
        
        let arguments = buildQEMUArguments(for: vm)
        qemuProcess?.arguments = arguments
        
        let pipe = Pipe()
        qemuProcess?.standardOutput = pipe
        qemuProcess?.standardError = pipe
        
        try qemuProcess?.run()
    }
    
    // MARK: - Stop QEMU
    func stopQEMU(vmId: String) {
        if let process = qemuProcess, process.isRunning {
            process.terminate()
            qemuProcess = nil
        }
    }
    
    // MARK: - Build QEMU Arguments
    private func buildQEMUArguments(for vm: VirtualMachine) -> [String] {
        var args: [String] = []
        
        // CPU configuration
        args.append(contentsOf: ["-cpu", "cortex-a72"])
        args.append(contentsOf: ["-smp", "cpus=\(vm.cpuCores)"])
        
        // Memory configuration
        args.append(contentsOf: ["-m", "\(vm.ramGB)G"])
        
        // Machine type (ARM64)
        args.append(contentsOf: ["-machine", "virt,gic-version=3"])
        
        // Storage configuration
        args.append(contentsOf: ["-drive", "file=\(vm.osImagePath),format=raw,if=virtio"])
        
        // Network configuration
        args.append(contentsOf: ["-net", "nic,model=virtio", "-net", "user,hostfwd=tcp::2222-:22"])
        
        // Display configuration
        args.append(contentsOf: ["-display", "none"])
        
        // Serial console
        args.append(contentsOf: ["-serial", "stdio"])
        
        // Enable JIT if available
        args.append(contentsOf: ["-enable-kvm"])
        
        // Daemonize
        args.append("-daemonize")
        
        return args
    }
    
    // MARK: - Get QEMU Path
    private func getQEMUPath() -> String {
        let paths = [
            "/usr/local/bin/qemu-system-aarch64",
            "/usr/bin/qemu-system-aarch64",
            "/opt/qemu/bin/qemu-system-aarch64",
            "/var/mobile/qemu/bin/qemu-system-aarch64"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        return "/usr/local/bin/qemu-system-aarch64"
    }
    
    // MARK: - Get QEMU Version
    func getQEMUVersion() throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: getQEMUPath())
        process.arguments = ["-version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        try process.run()
        process.waitUntilExit()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""
        
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Check QEMU Installation
    func isQEMUInstalled() -> Bool {
        return FileManager.default.fileExists(atPath: getQEMUPath())
    }
}

// MARK: - QEMU Error
enum QEMUError: LocalizedError {
    case qemuNotFound
    case launchFailed(String)
    case invalidConfiguration
    
    var errorDescription: String? {
        switch self {
        case .qemuNotFound:
            return "QEMU is not installed on this device"
        case .launchFailed(let reason):
            return "Failed to launch QEMU: \(reason)"
        case .invalidConfiguration:
            return "Invalid VM configuration"
        }
    }
}
