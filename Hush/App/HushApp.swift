//
//  HushApp.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import SwiftUI
import ComposableArchitecture

@main
struct HushApp: App {
    let store = Store(initialState: AppFeature.State()) {
        AppFeature()
    }

    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}
