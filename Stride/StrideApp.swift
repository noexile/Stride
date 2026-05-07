//
//  StrideApp.swift
//  Stride
//
//  Created by Alexander Zorov on 6.05.26.
//

import SwiftUI
import SwiftData

@main
struct StrideApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Shoe.self,
            Run.self,
            ShoeRunAssignment.self,
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
            TabView {
                Tab("Shoes", systemImage: "shoeprints.fill") {
                    ShoeListView()
                }
                Tab("Runs", systemImage: "figure.run") {
                    RunsView()
                }
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
