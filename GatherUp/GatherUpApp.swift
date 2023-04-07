//
//  GatherUpApp.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//

import SwiftUI
import Firebase

@main
struct GatherUpApp: App {
    @AppStorage("isLoading") var isLoading: Bool = false
    init() {
        FirebaseApp.configure()
        isLoading = false
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
