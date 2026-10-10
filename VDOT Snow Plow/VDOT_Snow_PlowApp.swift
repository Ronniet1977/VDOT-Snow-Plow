//
//  VDOT_Snow_PlowApp.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//

import SwiftUI

@main
struct VDOTSnowPlow: App {
    @UIApplicationDelegateAdaptor(
        AppDelegate.self
    )
    private var appDelegate
    
    @StateObject private var vm = TimeViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(vm)
        }
    }
}
