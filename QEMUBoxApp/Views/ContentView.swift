import SwiftUI

struct ContentView: View {
    @EnvironmentObject var vmManager: VMManager
    @EnvironmentObject var downloadManager: DownloadManager
    @EnvironmentObject var osRepository: OSRepository
    
    @State private var selectedTab: Int = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Tab 1: My Virtual Machines
            VMListView()
                .tabItem {
                    Label("My VMs", systemImage: "desktopcomputer")
                }
                .tag(0)
            
            // Tab 2: Download OS
            OSDownloadView()
                .tabItem {
                    Label {
                        VStack {
                            Image(systemName: "arrow.down.circle")
                            Text("Download OS")
                        }
                    }
                }
                .tag(1)
            
            // Tab 3: Settings
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(2)
        }
        .navigationTitle("QEMUBox")
    }
}

#Preview {
    ContentView()
        .environmentObject(VMManager.shared)
        .environmentObject(DownloadManager.shared)
        .environmentObject(OSRepository.shared)
}
