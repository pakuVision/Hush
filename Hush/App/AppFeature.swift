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
            case onboarding(OnboardingFeature.State)
            case cardList(CardListFeature.State)
        }
    }

    enum Action {
        case onAppear
        case decideInitialRoute
        case showOnboarding
        case showCardList
        
        case onboarding(OnboardingFeature.Action)
        case cardList(CardListFeature.Action)
    }
    
    @Dependency(\.userDefaultsClient) var userDefaultsClient

    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    try await Task.sleep(for: .seconds(0.5))
                    await send(.decideInitialRoute)
                }
                
            case .decideInitialRoute:
                return .run { send in
                    let done = try await userDefaultsClient.isOnboardingDone()
                    await send(done ? .showCardList : .showOnboarding)
                }
            case .showOnboarding:
                state.route = .onboarding(OnboardingFeature.State())
                return .none
            case .showCardList:
                state.route = .cardList(CardListFeature.State())
                return .none
                
            // onBoarding Delegate
            case .onboarding(.delegate(.finished)):
                state.route = .cardList(CardListFeature.State())
                return .none
                
            case .onboarding:
                return .none
            case .cardList:
                // CardListのアクションはここで処理しない
                return .none
            }
        }
        .ifLet(\.route.cardList, action: \.cardList) {
            CardListFeature()
        }
        .ifLet(\.route.onboarding, action: \.onboarding) {
            OnboardingFeature()
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
    
    var onboarding: OnboardingFeature.State? {
        get {
                    guard case .onboarding(let state) = self else { return nil }
                    return state
                }
                set {
                    guard let newValue = newValue else { return }
                    self = .onboarding(newValue)
                }
    }
}

