//
//  UserDefaultsClient.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/08.
//

import ComposableArchitecture
import Foundation

@DependencyClient
struct UserDefaultsClient: Sendable {
    var isOnboardingDone: @Sendable () async throws -> Bool
    var setIsOnboardingDone: @Sendable (Bool) async -> Void
}

extension UserDefaultsClient: DependencyKey {
    static let liveValue = UserDefaultsClient(
        isOnboardingDone: {
            UserDefaults.standard.bool(forKey: "onboarding_done")
        },
        setIsOnboardingDone: { done in
            UserDefaults.standard.set(done, forKey: "onboarding_done")
        }
    )
}

extension DependencyValues {
    var userDefaultsClient: UserDefaultsClient {
        get { self[UserDefaultsClient.self] }
        set { self[UserDefaultsClient.self] = newValue }
    }
}
