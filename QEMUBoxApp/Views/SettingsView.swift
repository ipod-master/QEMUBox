import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var vmManager: VMManager
    @State private var storageUsage: String = "Calculating..."
    @State private var qemuVersion: String = "Not installed"
    @State private var appVersion: String = "1.0.0"
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - App Info Section
                Section("About QEMUBox") {
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text(appVersion)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("QEMU Version")
                        Spacer()
                        Text(qemuVersion)
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // MARK: - Storage Section
                Section("Storage") {
                    HStack {
                        Text("Total Storage Used")
                        Spacer()
                        Text(storageUsage)
                            .foregroundColor(.secondary)
                    }
                    Button(action: calculateStorageUsage) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Refresh Storage Info")
                        }
                        .foregroundColor(.blue)
                    }
                }
                
                // MARK: - Virtual Machines Section
                Section("Virtual Machines") {
                    HStack {
                        Text("Total VMs")
                        Spacer()
                        Text("\(vmManager.virtualMachines.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Advanced Section
                Section("Advanced") {
                    NavigationLink(destination: AdvancedSettingsView()) {
                        HStack {
                            Image(systemName: "gearshape.2")
                            Text("Advanced Settings")
                        }
                    }
                    
                    Button(action: clearCache) {
                        HStack {
                            Image(systemName: "trash")
                            Text("Clear Cache")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // MARK: - Support Section
                Section("Support") {
                    Link(destination: URL(string: "https://github.com/ipod-master/QEMUBox")!) {
                        HStack {
                            Image(systemName: "book.fill")
                            Text("GitHub Repository")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                    
                    Link(destination: URL(string: "https://github.com/ipod-master/QEMUBox/issues")!) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                            Text("Report Issue")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.gray)
                        }
                    }
                }
                
                // MARK: - Legal Section
                Section("Legal") {
                    HStack {
                        Text("License")
                        Spacer()
                        Text("Apache 2.0")
                            .foregroundColor(.secondary)
                    }
                    Text("QEMUBox uses QEMU (GPLv2) and other open-source components")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                calculateStorageUsage()
                getQEMUVersion()
            }
        }
    }
    
    private func calculateStorageUsage() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        var totalSize: UInt64 = 0
        if let enumerator = fileManager.enumerator(at: documentsURL, includingPropertiesForKeys: [.fileSizeKey]) {
            for case let url as URL in enumerator {
                if let size = try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                    totalSize += UInt64(size ?? 0)
                }
            }
        }
        
        storageUsage = formatBytes(totalSize)
    }
    
    private func getQEMUVersion() {
        let wrapper = QEMUWrapper()
        if wrapper.isQEMUInstalled() {
            if let version = try? wrapper.getQEMUVersion() {
                qemuVersion = version.split(separator: "\n").first.map(String.init) ?? "Unknown"
            }
        } else {
            qemuVersion = "Not installed"
        }
    }
    
    private func clearCache() {
        let fileManager = FileManager.default
        let paths = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)
        
        for path in paths {
            do {
                try fileManager.removeItem(atPath: path)
                try fileManager.createDirectory(atPath: path, withIntermediateDirectories: true)
            } catch {
                print("Error clearing cache: \(error)")
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB, .useKB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct AdvancedSettingsView: View {
    @State private var enableJIT = false
    @State private var autoStartLastVM = false
    @State private var networkMode = "NAT"
    
    var body: some View {
        Form {
            Section("Performance") {
                Toggle("Enable JIT Acceleration", isOn: $enableJIT)
                    .help("Requires jailbreak with JIT support")
            }
            
            Section("Startup") {
                Toggle("Auto-start Last VM", isOn: $autoStartLastVM)
            }
            
            Section("Network") {
                Picker("Network Mode", selection: $networkMode) {
                    Text("NAT").tag("NAT")
                    Text("Bridge").tag("Bridge")
                    Text("Host-only").tag("Host-only")
                }
            }
            
            Section("Developer") {
                Text("Debug Mode: Disabled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Advanced Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    SettingsView()
        .environmentObject(VMManager.shared)
}
