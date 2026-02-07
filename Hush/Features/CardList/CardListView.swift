//
//  CardListView.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/02.
//

import SwiftUI
import ComposableArchitecture

struct CardListView: View {
    @Bindable var store: StoreOf<CardListFeature>

    var body: some View {
        NavigationStack {
            Group {
                if store.focusAreas.isEmpty {
                    emptyStateView
                } else {
                    listView
                }
            }
            .navigationTitle("Hush")
            .toolbar {
                if !store.focusAreas.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            store.send(.addButtonTapped)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .task {
                await store.send(.task).finish()
            }
            .sheet(item: $store.scope(state: \.destination?.addCard, action: \.destination.addCard)) { store in
                AddCardView(store: store)
            }
        }
    }

    private var emptyStateView: some View {
        VStack {
            Spacer()

            Button {
                store.send(.addButtonTapped)
            } label: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.blue)
            }

            Text("새로운 영역을 추가하세요")
                .font(.headline)
                .foregroundStyle(.secondary)
                .padding(.top, 16)

            Spacer()
        }
    }

    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(store.focusAreas) { area in
                    CardItemView(area: area)
                }
            }
            .padding()
        }
    }
}

struct CardItemView: View {
    let area: FocusArea

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(area.title)
                .font(.headline)

            Text(area.createdAt, style: .date)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
