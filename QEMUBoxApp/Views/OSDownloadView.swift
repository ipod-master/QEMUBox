import SwiftUI

struct OSDownloadView: View {
    @EnvironmentObject var osRepository: OSRepository
    @EnvironmentObject var downloadManager: DownloadManager
    @State private var searchText = ""
    @State private var selectedOS: OSImage?
    @State private var showingDownloadSheet = false
    @State private var expandedOS: String?
    
    var filteredOSes: [OSImage] {
        if searchText.isEmpty {
            return osRepository.availableOSes
        }
        return osRepository.availableOSes.filter { os in
            os.name.localizedCaseInsensitiveContains(searchText) ||
            os.version.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                if osRepository.availableOSes.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("Loading Operating Systems...")
                            .font(.headline)
                        ProgressView()
                    }
                    .padding()
                } else {
                    List {
                        ForEach(filteredOSes) { os in
                            OSDownloadItemView(
                                os: os,
                                isExpanded: expandedOS == os.id,
                                onExpand: {
                                    expandedOS = expandedOS == os.id ? nil : os.id
                                },
                                onDownload: {
                                    selectedOS = os
                                    showingDownloadSheet = true
                                }
                            )
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Download OS")
            .searchable(text: $searchText, prompt: "Search OS")
            .sheet(isPresented: $showingDownloadSheet, onDismiss: {
                selectedOS = nil
            }) {
                if let os = selectedOS {
                    DownloadConfirmationView(os: os)
                        .environmentObject(downloadManager)
                        .environmentObject(osRepository)
                }
            }
        }
    }
}

struct OSDownloadItemView: View {
    let os: OSImage
    let isExpanded: Bool
    let onExpand: () -> Void
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: getOSIcon(os.name))
                            .font(.title3)
                        Text(os.name)
                            .font(.headline)
                    }
                    Text(os.version)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .foregroundColor(.blue)
            }
            .contentShape(Rectangle())
            .onTapGesture(perform: onExpand)
            
            // Expanded Details
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Size: \(formatBytes(os.size))", systemImage: "externaldrive")
                        Spacer()
                        Label("Type: \(os.architecture)", systemImage: "cpu")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    
                    Text(os.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                    
                    Button(action: onDownload) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                            Text("Download & Create VM")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func getOSIcon(_ osName: String) -> String {
        switch osName.lowercased() {
        case "ubuntu": return "swift"
        case "fedora": return "circle.hexagongrid.fill"
        case "debian": return "swirl"
        case "alpine": return "mountain.2.fill"
        case "centos": return "cube.fill"
        case "macos": return "apple.logo"
        default: return "gearshape.fill"
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

struct DownloadConfirmationView: View {
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var osRepository: OSRepository
    @Environment(\.dismiss) var dismiss
    
    let os: OSImage
    @State private var vmName = ""
    @State private var cpuCores = 4
    @State private var ramGB = 4
    @State private var isDownloading = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("VM Configuration") {
                    TextField("VM Name", text: $vmName)
                        .onAppear { vmName = os.name + " VM" }
                    
                    Stepper("CPU Cores: \(cpuCores)", value: $cpuCores, in: 1...8)
                    Stepper("RAM: \(ramGB)GB", value: $ramGB, in: 1...16)
                }
                
                Section("Download Details") {
                    HStack {
                        Text("OS")
                        Spacer()
                        Text(os.name + " " + os.version)
                            .foregroundColor(.secondary)
                    }
                    HStack {
                        Text("Size")
                        Spacer()
                        Text(formatBytes(os.size))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section {
                    Button(action: startDownload) {
                        HStack {
                            if isDownloading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "arrow.down.circle.fill")
                            }
                            Text("Start Download")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                    }
                    .disabled(vmName.isEmpty || isDownloading)
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Download \(os.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    private func startDownload() {
        isDownloading = true
        downloadManager.downloadOS(os, vmName: vmName, cpuCores: cpuCores, ramGB: ramGB) { success in
            if success {
                dismiss()
            }
            isDownloading = false
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useGB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    OSDownloadView()
        .environmentObject(OSRepository.shared)
        .environmentObject(DownloadManager.shared)
}
