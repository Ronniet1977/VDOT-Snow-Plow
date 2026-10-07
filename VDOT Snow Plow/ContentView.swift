import SwiftUI

struct ContentView: View {
    @State private var showSetup = false
    @EnvironmentObject var vm: TimeViewModel
    
    var body: some View {
        TabView {
            TimesView()
                .tabItem { Label("Times", systemImage: "clock") }
            
            MapsView()
                .tabItem { Label("Maps", systemImage: "map") }
            
            ExportView()
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            
            NavigationStack {
                SettingsView(isSetupMode: false, onContinue: nil)
            }
            .tabItem { Label("Settings", systemImage: "gear") }
        }
        .onAppear {
            showSetup = !vm.isSetupComplete
        }
        .fullScreenCover(isPresented: $showSetup) {
            NavigationStack {
                SettingsView(isSetupMode: true) {
                    // Continue pressed inside SettingsView
                    showSetup = false
                }
            }
            .interactiveDismissDisabled(true)
        }
    }
}
