//
//  AddCardView.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import SwiftUI
import MapKit
import ComposableArchitecture

struct AddCardView: View {
    @Bindable var store: StoreOf<AddCardFeature>

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                TextField("タイトル", text: $store.title)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)

                if store.isLoadingMap {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.15))
                        .aspectRatio(1.0, contentMode: .fit)
                    
                    ProgressView("現在地を取得中...")
                } else {
                    // 地図（正方形）
                    MapViewContainer(
                        mapCenter: store.mapCenter,
                        selectedCoordinate: store.selectedCoordinate,
                        selectedAddress: store.selectedAddress,
                        isLoadingAddress: store.isLoadingAddress,
                        onMapTapped: { coordinate in
                            store.send(.mapTapped(coordinate))
                        }
                    )
                    .aspectRatio(1.0, contentMode: .fit)
                    .padding(.horizontal)
                }
                

                Spacer()

                Button("保存") {
                    store.send(.saveButtonTapped)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.title.isEmpty || store.selectedCoordinate == nil)
                .frame(maxWidth: .infinity)
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
            .navigationTitle("新しいエリアを追加")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                store.send(.onAppear)
            }
        }
    }
}

// MARK: - Map View Container

struct MapViewContainer: View {
    let mapCenter: Coordinate?
    let selectedCoordinate: Coordinate?
    let selectedAddress: String?
    let isLoadingAddress: Bool
    let onMapTapped: (Coordinate) -> Void

    @State private var region: MKCoordinateRegion

    init(
        mapCenter: Coordinate?,
        selectedCoordinate: Coordinate?,
        selectedAddress: String?,
        isLoadingAddress: Bool,
        onMapTapped: @escaping (Coordinate) -> Void
    ) {
        self.mapCenter = mapCenter
        self.selectedCoordinate = selectedCoordinate
        self.selectedAddress = selectedAddress
        self.isLoadingAddress = isLoadingAddress
        self.onMapTapped = onMapTapped

        // 地図の初期中心座標を設定
        _region = State(initialValue: MKCoordinateRegion(
            center: CLLocationCoordinate2D(
                latitude: mapCenter?.latitude ?? Coordinate.defaultLocation.latitude,
                longitude: mapCenter?.longitude ?? Coordinate.defaultLocation.longitude
            ),
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        ))
    }

    var body: some View {
        ZStack {
            Map(coordinateRegion: $region, interactionModes: .all, annotationItems: annotations) { item in
                MapAnnotation(coordinate: item.coordinate) {
                    VStack(spacing: 0) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
                }
            }
            .onTapGesture { location in
                handleMapTap(at: location)
            }
            .cornerRadius(12)
            
            // 주소 표시
            if let address = selectedAddress {
                VStack {
                    Spacer()
                    AddressLabel(address: address, isLoading: isLoadingAddress)
                        .padding(.bottom, 16)
                }
            } else if isLoadingAddress {
                VStack {
                    Spacer()
                    AddressLabel(address: "주소 로딩 중...", isLoading: true)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    private var annotations: [MapAnnotationModel] {
        if let coordinate = selectedCoordinate {
            return [MapAnnotationModel(coordinate: .init(latitude: coordinate.latitude, longitude: coordinate.longitude))]
        }
        return []
    }

    private func handleMapTap(at location: CGPoint) {
        // Map의 중심 좌표를 기준으로 탭 위치 계산
        let mapView = UIView(frame: .zero)
        let coordinate = convertPoint(location, to: region)
        onMapTapped(.init(latitude: coordinate.latitude, longitude: coordinate.longitude))

        // 지도 중심을 선택된 위치로 이동
        withAnimation {
            region.center = coordinate
        }
    }

    private func convertPoint(_ point: CGPoint, to region: MKCoordinateRegion) -> CLLocationCoordinate2D {
        // 화면 크기를 기준으로 좌표 변환
        let screenWidth = UIScreen.main.bounds.width - 32 // padding 고려
        let screenHeight = screenWidth // 정사각형

        let latitudeDelta = region.span.latitudeDelta
        let longitudeDelta = region.span.longitudeDelta

        let latitude = region.center.latitude + (0.5 - point.y / screenHeight) * latitudeDelta
        let longitude = region.center.longitude + (point.x / screenWidth - 0.5) * longitudeDelta

        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

// MARK: - Address Label

struct AddressLabel: View {
    let address: String
    let isLoading: Bool

    var body: some View {
        HStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.8)
            }

            Text(address)
                .font(.subheadline)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
        )
        .shadow(radius: 4)
    }
}

// MARK: - Map Annotation Model

struct MapAnnotationModel: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
}
