import SwiftUI

struct VMListView: View {
    @EnvironmentObject var vmManager: VMManager
    @State private var showingAddVM = false
    @State private var selectedVM: VirtualMachine?
    @State private var showingDeleteAlert = false
    @State private var vmToDelete: VirtualMachine?
    
    var body: some View {
        NavigationStack {
            ZStack {
                if vmManager.virtualMachines.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No Virtual Machines")
                            .font(.headline)
                        Text("Create your first VM or download an OS to get started")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button(action: { showingAddVM = true }) {
                            Label("Create VM", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                    .padding()
                } else {
                    List {
                        ForEach(vmManager.virtualMachines) { vm in
                            NavigationLink(destination: VMDetailView(vm: vm)) {
                                VMListItemView(vm: vm)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    vmToDelete = vm
                                    showingDeleteAlert = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("My Virtual Machines")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddVM = true }) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showingAddVM) {
                CreateVMView()
                    .environmentObject(vmManager)
            }
            .alert("Delete VM?", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let vm = vmToDelete {
                        vmManager.deleteVM(vm)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete \(vmToDelete?.name ?? "this VM")? This cannot be undone.")
            }
        }
    }
}

struct VMListItemView: View {
    let vm: VirtualMachine
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(vm.name)
                        .font(.headline)
                    Text(vm.osType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                        Text("\(vm.cpuCores)C")
                            .font(.caption)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "memorychip")
                        Text("\(vm.ramGB)GB")
                            .font(.caption)
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            if let lastRun = vm.lastRunTime {
                Text("Last run: \(lastRun, style: .date)")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VMListView()
        .environmentObject(VMManager.shared)
}
