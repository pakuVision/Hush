//
//  ScreenTimeClient.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/08.
//

import ComposableArchitecture
import Foundation
import FamilyControls

@DependencyClient
struct ScreenTimeClient: Sendable {
    var requestAuthrization: @Sendable () async throws -> ScreenTimeAuthorizationState
    var authorizationStatus: @Sendable () async throws -> ScreenTimeAuthorizationState
}

extension ScreenTimeClient: DependencyKey {
    static let liveValue = ScreenTimeClient(
        requestAuthrization: {
            let center = AuthorizationCenter.shared
            try await center.requestAuthorization(for: .individual)
            
            return switch center.authorizationStatus {
            case .approved: .approved
            case .denied: .denied
            case .notDetermined: .notDetermined
            @unknown default: .unknown
            }
        },
        authorizationStatus: {
            switch AuthorizationCenter.shared.authorizationStatus {
            case .approved: .approved
            case .denied: .denied
            case .notDetermined: .notDetermined
            @unknown default: .unknown
            }
        }
    )
}

extension DependencyValues {
    var screenTimeClient: ScreenTimeClient {
        get { self[ScreenTimeClient.self] }
        set { self[ScreenTimeClient.self] = newValue }
    }
}

enum ScreenTimeAuthorizationState: Equatable, Sendable {
    case approved
    case denied
    case notDetermined
    case unknown
}
