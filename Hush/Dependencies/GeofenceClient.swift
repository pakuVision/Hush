//
//  GeofenceClient.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/07.
//

import CoreLocation
import ComposableArchitecture
import Foundation

// 지오펜스 인증 결과
enum GeofenceAuthResult: Equatable {
    case authorized
    case unauthorized
    case denied
    case error(String)
}

// 지오펜스 영역 정의
struct GeofenceRegion: Equatable {
    let latitude: Double
    let longitude: Double
    let radius: Double // 미터 단위
    let identifier: String

    var clRegion: CLCircularRegion {
        CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
            radius: radius,
            identifier: identifier
        )
    }
}

@DependencyClient
struct GeofenceClient: Sendable {
    // 現在の権限ステータスを取得
    var getCurrentAuthorizationStatus: @Sendable () async -> CLAuthorizationStatus = { .notDetermined }

    var requestWhenInUseAuthorization: @Sendable () async throws -> CLAuthorizationStatus
    var requestAlwaysAuthorization: @Sendable () async throws -> CLAuthorizationStatus

    // 現在位置を取得
    var getCurrentLocation: @Sendable () async throws -> CLLocationCoordinate2D

    // 特定エリア内にいるかチェック
    var isInsideRegion: @Sendable (GeofenceRegion) async throws -> Bool
}

extension GeofenceClient: DependencyKey {
    static let liveValue: GeofenceClient = {
        let locationManager = CLLocationManager()

        return GeofenceClient(
            getCurrentAuthorizationStatus: {
                // 現在の権限ステータスを返す
                await LocationService.shared.authorizationStatus()
            },
            requestWhenInUseAuthorization: {
                await LocationService.shared.requestWhenInUseAuthorization()
            },
            requestAlwaysAuthorization: {
                await LocationService.shared.requestAlwaysAuthorization()
            },
            getCurrentLocation: {
                try await LocationService.shared.requestCurrentLocation()
            },
            isInsideRegion: { region in
                let currentLocation = try await liveValue.getCurrentLocation()
                let targetLocation = CLLocation(
                    latitude: region.latitude,
                    longitude: region.longitude
                )
                let currentCLLocation = CLLocation(
                    latitude: currentLocation.latitude,
                    longitude: currentLocation.longitude
                )

                let distance = currentCLLocation.distance(from: targetLocation)
                return distance <= region.radius
            }
        )
    }()

//    static let testValue = GeofenceClient(
//        requestAuthorization: { .authorizedWhenInUse },
//        getCurrentLocation: {
//            // 테스트용 기본 위치 (서울 시청)
//            CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780)
//        },
//        isInsideRegion: { _ in true },
//        authenticate: { _ in .authorized }
//    )
}

extension DependencyValues {
    var geofenceClient: GeofenceClient {
        get { self[GeofenceClient.self] }
        set { self[GeofenceClient.self] = newValue }
    }
}

// CLLocationManager가 Swift6 concurrency(동시성)의 규칙을 만족시키지 못해서 경고가 나므로
// 전체를 mainActor로 감싼 LocationService를 구현
@MainActor
final class LocationService: NSObject {
    static let shared = LocationService()
    
    let manager = CLLocationManager()
    
    private var continuation: CheckedContinuation<CLLocationCoordinate2D, Error>?
    private var authContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }
    
    // Status를 반환
    func authorizationStatus() -> CLAuthorizationStatus {
        manager.authorizationStatus
    }
    
    func requestWhenInUseAuthorization() async -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        guard current == .notDetermined else { return current }
        
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func requestAlwaysAuthorization() async -> CLAuthorizationStatus {
        let current = manager.authorizationStatus
        guard current == .authorizedWhenInUse else {
            return current
        }
        
        return await withCheckedContinuation { continuation in
            self.authContinuation = continuation
            manager.requestAlwaysAuthorization()
        }
    }
    
    func requestAlwaysAuthorization() {
        manager.requestAlwaysAuthorization()
    }
    
    func requestCurrentLocation() async throws -> CLLocationCoordinate2D {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            manager.requestLocation()
        }
    }
    
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        continuation?.resume(returning: location.coordinate)
        continuation = nil
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: any Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        authContinuation?.resume(returning: status)
        authContinuation = nil
    }
}


// MARK: - Location Delegate

private class LocationDelegate: NSObject, CLLocationManagerDelegate {
    let onLocation: (CLLocation) -> Void
    let onError: (Error) -> Void

    init(
        onLocation: @escaping (CLLocation) -> Void,
        onError: @escaping (Error) -> Void
    ) {
        self.onLocation = onLocation
        self.onError = onError
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        onLocation(location)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        onError(error)
    }
}
