//
//  OnboardingFeature.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/08.
//

import ComposableArchitecture
import Foundation
import FamilyControls

@Reducer
struct OnboardingFeature {
    
    @ObservableState
    struct State: Equatable {
        var page: Int = 0
        var totalPages: Int = 3
        var isLastPage: Bool {
            page == totalPages - 1
        }
        
        var isRequestingScreenTime = false
        var screenTimeStatusText: String?
    }
    
    enum Action {
        case nextTapped
        case backTapped
        case skipTapped
        
        case allowScreenTimeTapped
        case screenTimeAuthResponse(Result<ScreenTimeAuthorizationState, Error>)
        case delegate(Delegate)
        
        enum Delegate {
            case finished
        }
    }
    
    @Dependency(\.screenTimeClient) var screenTimeClient
    @Dependency(\.userDefaultsClient) var userDefaultsClient
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
                
            case .nextTapped:
                state.page = min(state.page + 1, state.totalPages - 1)
                return .none
            case .backTapped:
                state.page = max(state.page - 1, 0)
                return .none
            case .skipTapped:
                return .run { send in
                    await userDefaultsClient.setIsOnboardingDone(true)
                    await send(.delegate(.finished))
                }
                
            case .allowScreenTimeTapped:
                state.isRequestingScreenTime = true
                state.screenTimeStatusText = nil
                
                return .run { send in
                    await send(.screenTimeAuthResponse(Result {
                        try await screenTimeClient.requestAuthrization()
                    }))
                }
                
            case .screenTimeAuthResponse(.success(let status)):
                state.isRequestingScreenTime = false
                
                switch status {
                case .approved:
                    state.screenTimeStatusText = "許可されました。"
                    return .run { send in
                        await userDefaultsClient.setIsOnboardingDone(true)
                        await send(.delegate(.finished))
                    }
                case .denied:
                    state.screenTimeStatusText = "許可されませんでした。設定アプリから変更できます"
                    return .none
                    
                case .notDetermined:
                    state.screenTimeStatusText = "未設定の状態です。"
                    return .none
                     
                case .unknown:
                    state.screenTimeStatusText = "不明な状態です。"
                    return .none
                }
            case .screenTimeAuthResponse(.failure):
                state.isRequestingScreenTime = false
                state.screenTimeStatusText = "エラーが発生しました。もう一度お試しください。"
                return .none
                
            case .delegate:
                return .none
            }
        }
    }
}
