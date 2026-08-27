import SwiftUI

@main
struct QEMUBoxApp: App {
    @StateObject private var vmManager = VMManager.shared
    @StateObject private var downloadManager = DownloadManager.shared
    @StateObject private var osRepository = OSRepository.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vmManager)
                .environmentObject(downloadManager)
                .environmentObject(osRepository)
                .onAppear {
                    initializeApp()
                }
        }
    }
    
    private func initializeApp() {
        // Initialize app state
        vmManager.loadVirtualMachines()
        osRepository.fetchAvailableOSes()
        downloadManager.restoreDownloads()
    }
}
