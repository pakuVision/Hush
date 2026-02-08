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

        @CasePathable
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

/*
 Cannot convert value of type 'KeyPath<AppFeature.State, @Sendable (OnboardingFeature.State) -> AppFeature.State.Route>' to expected argument type 'WritableKeyPath<AppFeature.State, OnboardingFeature.State?>'
 
 
 
 KeyPath<AppFeature.State, @Sendable (OnboardingFeature.State) -> AppFeature.State.Route>  를
 WritableKeyPath<AppFeature.State, OnboardingFeature.State?> 로 변환할 수 없다는 에러
 
 즉, .ifLet(\. 에서 요구하는 KeyPath의 형태와 실제로 설정한 keyPath의 형태가 다르기 때문에 에러가 발생
 
 부모 State안에, optional child state(ChildState?)가 있으면
 그것을 읽고 + 쓸 수 있어야 한다.
 
 -> WritableKeyPath<ParentState, ChildState?>
 
 핵심
  - Writable -> Set 가능해야 함
  - ChildState? -> Optional 이어야 함
 
 근데 에러가 난 원인
 \.route.cardList
 
 enum Route { case cardList(CardListFeature.State)
 
 즉 .cardList는 enum case이고, 이것은 read only 패턴이다.  (WritableKeyPath가 아님)
 
 -----
 .ifLet은 내부에서 이런 일을 한다
 
 if let childState = state.route.cardList {
     // child reducer실행
     childReducer(&childState, action)
     state.route.cardList = childState <-  set하는 부분이 필요
 } else {
     // child Reducer 실행 안 함
 }
 
 ----
 
 extension으로 해결 된 이유
 
 -> getter + setter computed property로 바꾸어줬기 때문에
 
 */

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

