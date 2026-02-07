//
//  AppFeature.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/07.
//

import ComposableArchitecture
import CoreLocation
import Foundation

@Reducer
struct AppFeature {

    @ObservableState
    struct State: Equatable {
        var route: Route = .splash

        enum Route: Equatable {
            case splash
            case cardList(CardListFeature.State)
        }
    }

    enum Action {
        case onAppear
        case showCardList
        case cardList(CardListFeature.Action)
    }

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(0.5))
                    await send(.showCardList)
                }
            case .showCardList:
                state.route = .cardList(CardListFeature.State())
                return .none
            case .cardList:
                // CardListのアクションはここで処理しない
                return .none
            }
        }
        .ifLet(\.route.cardList, action: \.cardList) {
            CardListFeature()
        }
    }
}

// MARK: - Route CasePath Helper

extension AppFeature.State.Route {
    var cardList: CardListFeature.State? {
        get {
            guard case .cardList(let state) = self else { return nil }
            return state
        }
        set {
            guard let newValue = newValue else { return }
            self = .cardList(newValue)
        }
    }
}
