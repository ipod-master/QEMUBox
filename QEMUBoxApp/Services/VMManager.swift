import Foundation
import Combine

class VMManager: ObservableObject {
    static let shared = VMManager()
    
    @Published var virtualMachines: [VirtualMachine] = []
    @Published var runningVMId: String?
    
    private let fileManager = FileManager.default
    private let vmDirectoryURL: URL
    private let vmsListURL: URL
    
    init() {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        vmDirectoryURL = documentsURL.appendingPathComponent("QEMUBox_VMs", isDirectory: true)
        vmsListURL = documentsURL.appendingPathComponent("vms_list.json")
        
        // Create VMs directory if it doesn't exist
        try? fileManager.createDirectory(at: vmDirectoryURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Load VMs
    func loadVirtualMachines() {
        if let data = try? Data(contentsOf: vmsListURL),
           let decoded = try? JSONDecoder().decode([VirtualMachine].self, from: data) {
            DispatchQueue.main.async {
                self.virtualMachines = decoded
            }
        }
    }
    
    // MARK: - Save VMs
    private func saveVirtualMachines() {
        if let encoded = try? JSONEncoder().encode(virtualMachines) {
            try? encoded.write(to: vmsListURL)
        }
    }
    
    // MARK: - Create VM
    func createVM(name: String, osType: String, osPath: URL, cpuCores: Int, ramGB: Int) -> VirtualMachine {
        let vm = VirtualMachine(
            id: UUID().uuidString,
            name: name,
            osType: osType,
            osImagePath: osPath.path,
            cpuCores: cpuCores,
            ramGB: ramGB,
            storageGB: 20,
            createdAt: Date(),
            lastRunTime: nil
        )
        
        virtualMachines.append(vm)
        saveVirtualMachines()
        
        return vm
    }
    
    // MARK: - Update VM
    func updateVM(_ vm: VirtualMachine) {
        if let index = virtualMachines.firstIndex(where: { $0.id == vm.id }) {
            virtualMachines[index] = vm
            saveVirtualMachines()
        }
    }
    
    // MARK: - Delete VM
    func deleteVM(_ vm: VirtualMachine) {
        // Delete VM files
        let vmPath = vmDirectoryURL.appendingPathComponent(vm.id)
        try? fileManager.removeItem(at: vmPath)
        
        // Remove from list
        virtualMachines.removeAll { $0.id == vm.id }
        saveVirtualMachines()
    }
    
    // MARK: - Launch VM
    func launchVM(_ vm: VirtualMachine, completion: @escaping (Bool, String?) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let qemuWrapper = QEMUWrapper()
                try qemuWrapper.launchQEMU(for: vm)
                
                DispatchQueue.main.async {
                    self.runningVMId = vm.id
                    var updatedVM = vm
                    updatedVM.lastRunTime = Date()
                    self.updateVM(updatedVM)
                    completion(true, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
    
    // MARK: - Stop VM
    func stopVM(_ vm: VirtualMachine) {
        QEMUWrapper().stopQEMU(vmId: vm.id)
        DispatchQueue.main.async {
            self.runningVMId = nil
        }
    }
    
    // MARK: - Get VM by ID
    func getVM(by id: String) -> VirtualMachine? {
        return virtualMachines.first { $0.id == id }
    }
    
    // MARK: - Get VM storage path
    func getVMStoragePath(_ vm: VirtualMachine) -> URL {
        return vmDirectoryURL.appendingPathComponent(vm.id, isDirectory: true)
    }
}

// MARK: - VirtualMachine Model
struct VirtualMachine: Identifiable, Codable {
    let id: String
    var name: String
    var osType: String
    var osImagePath: String
    var cpuCores: Int
    var ramGB: Int
    var storageGB: Int
    var createdAt: Date
    var lastRunTime: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, osType, osImagePath, cpuCores, ramGB, storageGB, createdAt, lastRunTime
    }
}
