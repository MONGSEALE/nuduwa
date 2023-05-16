//
//  GatherUpApp.swift
//  GatherUp
//
//  Created by DaelimCI10001 on 2023/03/17.
//
// dribbble.com
// figma.com

import SwiftUI
import Firebase

@main
struct GatherUpApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
