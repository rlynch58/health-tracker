//
//  HealthTrackerApp.swift
//  HealthTracker
//
//  Created by Rob Lynch on 7/26/26.
//

import SwiftUI
import SwiftData
import HealthTrackerData

@main
struct HealthTrackerApp: App {
    let sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Meal.self,
            DailyLog.self,
            GoalPeriod.self
        ])

        guard let appGroupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: "group.com.roblynch.HealthTracker")
        else {
            fatalError("Could not find App Group container. Check the App Groups capability is enabled and the identifier matches exactly.")
        }

        let storeURL = appGroupURL.appendingPathComponent("HealthTracker.sqlite")
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            url: storeURL,
            cloudKitDatabase: .private("iCloud.com.roblynch.HealthTracker")
        )

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
