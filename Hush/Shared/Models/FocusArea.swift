//
//  FocusArea.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import Foundation

struct FocusArea: Equatable, Identifiable, Sendable {
    let id: UUID
    var title: String
    let latitude: Double
    let longitude: Double
    let address: String
    let createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        latitude: Double,
        longitude: Double,
        address: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.createdAt = createdAt
    }
}
