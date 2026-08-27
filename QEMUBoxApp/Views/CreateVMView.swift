import SwiftUI

struct CreateVMView: View {
    @EnvironmentObject var vmManager: VMManager
    @Environment(\.dismiss) var dismiss
    
    @State private var vmName = ""
    @State private var selectedOS = "Ubuntu"
    @State private var cpuCores = 4
    @State private var ramGB = 4
    @State private var storageGB = 20
    @State private var isCreating = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let osOptions = ["Ubuntu", "Fedora", "Debian", "Alpine Linux", "CentOS Stream"]
    
    var isFormValid: Bool {
        !vmName.isEmpty && cpuCores > 0 && ramGB > 0 && storageGB > 0
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("VM Name") {
                    TextField("Enter VM name", text: $vmName)
                        .textContentType(.none)
                }
                
                Section("Operating System") {
                    Picker("Select OS", selection: $selectedOS) {
                        ForEach(osOptions, id: \.self) { os in
                            Text(os).tag(os)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }
                
                Section("Hardware Configuration") {
                    Stepper("CPU Cores: \(cpuCores)", value: $cpuCores, in: 1...8)
                    
                    Stepper("RAM: \(ramGB)GB", value: $ramGB, in: 1...16)
                    
                    Stepper("Storage: \(storageGB)GB", value: $storageGB, in: 1...256)
                }
                
                Section("Summary") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Configuration")
                            Spacer()
                            Text("\(cpuCores)C • \(ramGB)GB • \(storageGB)GB")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                        Text("You can modify these settings later in the VM details")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: createVM) {
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                            }
                            Text("Create VM")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .disabled(!isFormValid || isCreating)
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Create Virtual Machine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createVM() {
        guard isFormValid else { return }
        
        isCreating = true
        
        // Create a temporary OS image path
        // In a real scenario, this would come from the downloaded OS
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let osImagePath = documentsURL.appendingPathComponent("temp_os.iso")
        
        let vm = vmManager.createVM(
            name: vmName,
            osType: selectedOS,
            osPath: osImagePath,
            cpuCores: cpuCores,
            ramGB: ramGB
        )
        
        isCreating = false
        dismiss()
    }
}

#Preview {
    CreateVMView()
        .environmentObject(VMManager.shared)
}
