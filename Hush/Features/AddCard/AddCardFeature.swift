//
//  AddCardFeature.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import Foundation
import CoreLocation
import FamilyControls
import ComposableArchitecture
import ManagedSettings

@Reducer
struct AddCardFeature {
    @ObservableState
    struct State: Equatable {
        var title: String = ""
        var selectedCoordinate: Coordinate?
        var selectedAddress: String?
        var isLoadingAddress: Bool = false

        var mapCenter: Coordinate?
        var isLoadingMap: Bool = true

        // ブロック対象アプリ・カテゴリ
        // FamilyActivitySelectionはEquatableではないためトークンに分けて保持
        var isActivityPickerPresented: Bool = false
        var selectedApplicationTokens: Set<ApplicationToken> = []
        var selectedCategoryTokens: Set<ActivityCategoryToken> = []
    }

    enum Action: BindableAction {
        case binding(BindingAction<State>)
        case onAppear
        case currentLocationFetched(Result<Coordinate, Error>)
        case mapTapped(Coordinate)
        case addressFetched(Result<String, Error>)
        case selectActivitiesButtonTapped
        // ViewのFamilyActivitySelectionからトークンを受け取る
        case activitySelectionChanged(FamilyActivitySelection)
        case saveButtonTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case save(title: String, coordinate: Coordinate, address: String)
        }
    }

    @Dependency(\.geocodeClient) var geocodeClient
    @Dependency(\.geofenceClient) var geofenceClient

    var body: some Reducer<State, Action> {
        BindingReducer()

        Reduce { state, action in
            switch action {
            case .binding:
                return .none

            case .onAppear:
                // 位置情報権限を確認して現在地を取得
                return .run { send in
                    let status = await geofenceClient.getCurrentAuthorizationStatus()
                    
                    guard status == .authorizedAlways || status == .authorizedWhenInUse else {
                        // 権限なし！
                        await send(.currentLocationFetched(.failure(NSError())))
                        return
                    }
                    
                    do {
                        let location = try await geofenceClient.getCurrentLocation()
                        let coordinate = await Coordinate(latitude: location.latitude, longitude: location.longitude)
                        await send(.currentLocationFetched(.success(coordinate)))
                    } catch {
                        await send(.currentLocationFetched(.failure(error)))
                    }
                }

            case .currentLocationFetched(.success(let coordinate)):
                // 現在地取得成功 - 地図の中心を更新
                state.mapCenter = coordinate
                state.isLoadingMap = false
                return .none

            case .currentLocationFetched(.failure):
                // 現在地取得失敗 - デフォルト位置を使用（既に設定済み）
                state.mapCenter = .defaultLocation
                state.isLoadingMap = false
                return .none

            case .mapTapped(let coordinate):
                state.selectedCoordinate = coordinate
                state.isLoadingAddress = true
                state.selectedAddress = nil

                return .run { send in
                    await send(.addressFetched(
                        Result { try await geocodeClient.getAddress(coordinate) }
                    ))
                }

            case .addressFetched(.success(let address)):
                state.isLoadingAddress = false
                state.selectedAddress = address
                return .none

            case .addressFetched(.failure(let error)):
                state.isLoadingAddress = false
                state.selectedAddress = "주소를 가져올 수 없습니다"
                print("❌ Geocode error: \(error)")
                return .none

            case .selectActivitiesButtonTapped:
                // アクティビティピッカーを表示
                state.isActivityPickerPresented = true
                return .none

            case let .activitySelectionChanged(selection):
                // ViewからFamilyActivitySelectionを受け取りトークンに分解
                state.selectedApplicationTokens = selection.applicationTokens
                state.selectedCategoryTokens = selection.categoryTokens
                state.isActivityPickerPresented = false
                return .none

            case .saveButtonTapped:
                guard !state.title.isEmpty,
                      let coordinate = state.selectedCoordinate,
                      let address = state.selectedAddress else {
                    return .none
                }
                return .send(.delegate(.save(
                    title: state.title,
                    coordinate: coordinate,
                    address: address
                )))

            case .delegate:
                return .none
            }
        }
    }
}
