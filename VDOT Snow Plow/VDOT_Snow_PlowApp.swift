//
//  VDOT_Snow_PlowApp.swift
//  VDOT Snow Plow
//
//  Created by Ronald Thayer Jr on 2/11/26.
//

import SwiftUI
import SwiftData

@main
struct VDOT_Snow_PlowApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
