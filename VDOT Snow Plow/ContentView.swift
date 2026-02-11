//
//  ContentView.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var vm = TimeViewModel()
    
    var body: some View {
        TabView {
            TimesView()
                .environmentObject(vm)
                .tabItem { Label("Times", systemImage: "clock") }
            
            MapsView()
                .environmentObject(vm)
                .tabItem { Label("Maps", systemImage: "map") }
            
            ExportView()
                .environmentObject(vm)
                .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
            
            SettingsView()
                .environmentObject(vm)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
