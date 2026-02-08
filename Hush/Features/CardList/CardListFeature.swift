//
//  CardListFeature.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import Foundation
import ComposableArchitecture
import CoreLocation

@Reducer
struct CardListFeature {
    
    @Reducer
    enum Destination {
        case addCard(AddCardFeature)
    }
    
    @ObservableState
    struct State: Equatable {
        @Presents var destination: Destination.State?
        
        var focusAreas: [FocusArea] = []
        var isLoading: Bool = false
        var locationAuthStatus: CLAuthorizationStatus?
        
    }

    enum Action {
        case task
        case addButtonTapped
        case locationAuthStatusChecked(CLAuthorizationStatus)
        case fetchResponse([FocusArea])
        case destination(PresentationAction<Destination.Action>)
    }
    
    @Dependency(\.coreDataClient) var coreDataClient
    @Dependency(\.geofenceClient) var geofenceClient
    @Dependency(\.openSettings) var openSettings
    
    var body: some Reducer<State, Action> {
        Reduce { state, action in
            switch action {
            case .task:
                state.isLoading = true
                return .run { send in
                    let areas = try await coreDataClient.fetch()
                    await send(.fetchResponse(areas))
                }
            case .addButtonTapped:
                //state.destination = .addCard(AddCardFeature.State())
                return .run { send in
                    let status = await geofenceClient.getCurrentAuthorizationStatus()
                    await send(.locationAuthStatusChecked(status))
                }
                
            case let .locationAuthStatusChecked(status):
                state.locationAuthStatus = status
                print("status!!aaa: \(status)")
                switch status {
                case .authorizedWhenInUse, .authorizedAlways:
                    state.destination = .addCard(AddCardFeature.State())
                    
                case .notDetermined:
                    // 아직 요청 안 함 -> 안내 UI
                    return .run { send in
                        do {
                            print("do!!!!!")
                            let status = try await geofenceClient.requestWhenInUseAuthorization()
                            print("status!!: \(status)")
                            await send(.locationAuthStatusChecked(status))
                        } catch {}
                    }
                    
                case .denied, .restricted:
                    // 유저가 막음 -> Setting안내
                    return .run { send in
                        await openSettings()
                    }
                    
                @unknown default:
                    fatalError()
                }
                return .none
                
            case let .fetchResponse(areas):
                state.isLoading = false
                state.focusAreas = areas
                return .none
                
            case let .destination(.presented(.addCard(.delegate(.save(title, coordinate, address))))):
                state.destination = nil
                
                return .run { send in
                    try await coreDataClient.save(
                        title,
                        coordinate.latitude,
                        coordinate.longitude,
                        address
                    )
                    let areas = try await coreDataClient.fetch()
                    await send(.fetchResponse(areas))
                }
            case .destination:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination)
    }
}

extension CardListFeature.Destination.State: Equatable { }
