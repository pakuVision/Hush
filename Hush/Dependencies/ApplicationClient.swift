//
//  ApplicationClient.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/07.
//

import ComposableArchitecture
import Foundation
import UIKit

@DependencyClient
struct ApplicationClient: Sendable {
    var openURL: @Sendable (URL) async -> Bool = { _ in false }
    var openSettings: @Sendable () async -> Bool = { false }
}

extension ApplicationClient: DependencyKey {
    static let liveValue = ApplicationClient(
        openURL: { url in
            await UIApplication.shared.open(url)
        },
        openSettings: {
            guard let url = URL(string: UIApplication.openSettingsURLString) else {
                return false
            }
            return await UIApplication.shared.open(url)
        }
    )

    static let testValue = ApplicationClient(
        openURL: { _ in true },
        openSettings: { true }
    )
}

extension DependencyValues {
    var applicationClient: ApplicationClient {
        get { self[ApplicationClient.self] }
        set { self[ApplicationClient.self] = newValue }
    }
}
