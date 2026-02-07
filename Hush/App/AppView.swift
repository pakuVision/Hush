//
//  AppView.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/07.
//

import ComposableArchitecture
import SwiftUI

struct AppView: View {
    @Bindable var store: StoreOf<AppFeature>

    var body: some View {
        switch store.route {
        case .splash:
            SplashView()
                .onAppear {
                    store.send(.onAppear)
                }

        case .cardList:
            if let cardListStore = store.scope(state: \.route.cardList, action: \.cardList) {
                CardListView(store: cardListStore)
            }
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Text("Splash")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
    }
}
