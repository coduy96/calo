//
//  calorietrackerApp.swift
//  calorietracker
//
//  Created by Apoorv Darshan on 05/02/26.
//

import SwiftUI

@main
struct calorietrackerApp: App {
    @State private var foodStore = FoodStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(foodStore)
                .preferredColorScheme(.light)
        }
    }
}
