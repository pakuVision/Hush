//
//  GeocodeClient.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/07.
//

import CoreLocation
import ComposableArchitecture
import Foundation

struct Coordinate: Equatable, Sendable {
    let latitude: Double
    let longitude: Double

    init(latitude: Double, longitude: Double) {
        self.latitude = latitude
        self.longitude = longitude
    }
    // 日本で最もよく使われる地域（東京・新宿）
    static let defaultLocation = Coordinate(
        latitude: 35.6896,
        longitude: 139.7006
    )
}

@DependencyClient
struct GeocodeClient: Sendable {
    // 좌표로 주소 가져오기 (Reverse Geocoding)
    var getAddress: @Sendable (_ coordinate: Coordinate) async throws -> String
}

extension GeocodeClient: DependencyKey {
    static let liveValue = GeocodeClient(
        getAddress: { coordinate in
            let geocoder = CLGeocoder()
            let location = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

            let placemarks = try await geocoder.reverseGeocodeLocation(location)

            guard let placemark = placemarks.first else {
                throw GeocodeError.noAddress
            }

            // 한국 주소 형식으로 변환
            var addressComponents: [String] = []

            if let country = placemark.country {
                addressComponents.append(country)
            }
            if let administrativeArea = placemark.administrativeArea {
                addressComponents.append(administrativeArea)
            }
            if let locality = placemark.locality {
                addressComponents.append(locality)
            }
            if let subLocality = placemark.subLocality {
                addressComponents.append(subLocality)
            }
            if let thoroughfare = placemark.thoroughfare {
                addressComponents.append(thoroughfare)
            }
            if let subThoroughfare = placemark.subThoroughfare {
                addressComponents.append(subThoroughfare)
            }

            return addressComponents.joined(separator: " ")
        }
    )

    static let testValue = GeocodeClient(
        getAddress: { coordinate in
            "대한민국 서울특별시 중구 세종대로 110"
        }
    )
}

extension DependencyValues {
    var geocodeClient: GeocodeClient {
        get { self[GeocodeClient.self] }
        set { self[GeocodeClient.self] = newValue }
    }
}

// MARK: - Error

enum GeocodeError: Error, LocalizedError {
    case noAddress

    var errorDescription: String? {
        switch self {
        case .noAddress:
            return "주소를 찾을 수 없습니다"
        }
    }
}
