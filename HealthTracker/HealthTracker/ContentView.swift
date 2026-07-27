//
//  ContentView.swift
//  HealthTracker
//
//  Created by Rob Lynch on 7/26/26.
//

import SwiftUI
import SwiftData
import HealthTrackerData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
        .onAppear {
            let store = DailyLogStore(context: modelContext)
            let testDateKey = "2026-07-27-SMOKETEST"
            let log = store.fetchOrCreate(dateKey: testDateKey)
            log.waterOz = 64
            try? modelContext.save()

            let readBack = store.fetchOrCreate(dateKey: testDateKey)
            print("SMOKE TEST: dateKey=\(readBack.dateKey), waterOz=\(String(describing: readBack.waterOz))")
        }
    }
}

#Preview {
    ContentView()
}
