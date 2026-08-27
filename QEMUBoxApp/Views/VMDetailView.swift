import SwiftUI

struct VMDetailView: View {
    @EnvironmentObject var vmManager: VMManager
    @Environment(\.dismiss) var dismiss
    
    let vm: VirtualMachine
    @State private var isRunning = false
    @State private var showingLaunchError = false
    @State private var launchErrorMessage = ""
    @State private var isLaunching = false
    
    var body: some View {
        ZStack {
            Form {
                // MARK: - Status Section
                Section("Status") {
                    HStack {
                        Text("State")
                        Spacer()
                        HStack(spacing: 8) {
                            Circle()
                                .fill(isRunning ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                            Text(isRunning ? "Running" : "Stopped")
                                .foregroundColor(isRunning ? .green : .gray)
                        }
                    }
                }
                
                // MARK: - Configuration Section
                Section("Configuration") {
                    HStack {
                        Text("Name")
                        Spacer()
                        Text(vm.name)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Operating System")
                        Spacer()
                        Text(vm.osType)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("CPU Cores")
                        Spacer()
                        Text("\(vm.cpuCores)")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("RAM")
                        Spacer()
                        Text("\(vm.ramGB)GB")
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Storage")
                        Spacer()
                        Text("\(vm.storageGB)GB")
                            .foregroundColor(.secondary)
                    }
                }
                
                // MARK: - Image Section
                Section("OS Image") {
                    HStack {
                        Text("Path")
                        Spacer()
                        Text(vm.osImagePath)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                
                // MARK: - Date Section
                Section("Timeline") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(vm.createdAt, style: .date)
                            .foregroundColor(.secondary)
                    }
                    if let lastRun = vm.lastRunTime {
                        HStack {
                            Text("Last Run")
                            Spacer()
                            Text(lastRun, style: .date)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // MARK: - Actions Section
                Section {
                    if isRunning {
                        Button(role: .destructive) {
                            stopVM()
                        } label: {
                            HStack {
                                Image(systemName: "stop.fill")
                                Text("Stop VM")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.red)
                        }
                    } else {
                        Button {
                            launchVM()
                        } label: {
                            HStack {
                                if isLaunching {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text("Launch VM")
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                        }
                        .disabled(isLaunching)
                        .listRowBackground(Color.blue)
                    }
                    
                    NavigationLink(destination: VMConfigView(vm: vm)) {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                            Text("Edit Configuration")
                        }
                    }
                }
            }
            .navigationTitle(vm.name)
            .navigationBarTitleDisplayMode(.inline)
            .alert("Launch Error", isPresented: $showingLaunchError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(launchErrorMessage)
            }
        }
        .onAppear {
            isRunning = vmManager.runningVMId == vm.id
        }
    }
    
    private func launchVM() {
        isLaunching = true
        vmManager.launchVM(vm) { success, error in
            isLaunching = false
            if success {
                isRunning = true
            } else {
                launchErrorMessage = error ?? "Unknown error occurred"
                showingLaunchError = true
            }
        }
    }
    
    private func stopVM() {
        vmManager.stopVM(vm)
        isRunning = false
    }
}

struct VMConfigView: View {
    @EnvironmentObject var vmManager: VMManager
    @Environment(\.dismiss) var dismiss
    
    var vm: VirtualMachine
    @State private var name: String = ""
    @State private var cpuCores: Int = 4
    @State private var ramGB: Int = 4
    
    var body: some View {
        Form {
            Section("VM Details") {
                TextField("VM Name", text: $name)
                
                Stepper("CPU Cores: \(cpuCores)", value: $cpuCores, in: 1...8)
                
                Stepper("RAM: \(ramGB)GB", value: $ramGB, in: 1...16)
            }
            
            Section {
                Button("Save Changes") {
                    saveChanges()
                }
                .frame(maxWidth: .infinity)
                .foregroundColor(.blue)
            }
        }
        .navigationTitle("Edit VM")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            name = vm.name
            cpuCores = vm.cpuCores
            ramGB = vm.ramGB
        }
    }
    
    private func saveChanges() {
        var updatedVM = vm
        updatedVM.name = name
        // Note: CPU and RAM changes would require VM reconfiguration
        vmManager.updateVM(updatedVM)
        dismiss()
    }
}

#Preview {
    NavigationStack {
        VMDetailView(vm: VirtualMachine(
            id: "test-1",
            name: "Ubuntu 24.04",
            osType: "Ubuntu",
            osImagePath: "/path/to/ubuntu.iso",
            cpuCores: 4,
            ramGB: 4,
            storageGB: 20,
            createdAt: Date(),
            lastRunTime: Date()
        ))
        .environmentObject(VMManager.shared)
    }
}
