//
//  OnboardingView.swift
//  Hush
//
//  Created by boardguy.vision on 2026/02/08.
//

import ComposableArchitecture
import SwiftUI

struct OnboardingView: View {
    @Bindable var store: StoreOf<OnboardingFeature>

    var body: some View {
        VStack(spacing: 0) {
//            TabView(selection: $store.page) {
//                page1.tag(0)
//                page2.tag(1)
//                page3.tag(2)
//            }
//            .tabViewStyle(.page(indexDisplayMode: .always))
//            .padding(.top, 20)

            Spacer()

            if let text = store.screenTimeStatusText {
                Text(text)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 8)
            }

            buttonArea
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
    }

    private var page1: some View {
        VStack(spacing: 12) {
            Image(systemName: "location.fill")
                .font(.system(size: 44))
            Text("場所に入った瞬間、\n自動でアプリをブロック")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
            Text("勉強・仕事の場所を登録すると、\n集中を邪魔するアプリを自動で制限できます。")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var page2: some View {
        VStack(spacing: 12) {
            Image(systemName: "apps.iphone")
                .font(.system(size: 44))
            Text("ブロックするアプリは\nあなたが選べます")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
            Text("SNSやゲームなど、\n必要なものだけを選択してブロックします。")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var page3: some View {
        VStack(spacing: 12) {
            Image(systemName: "hourglass")
                .font(.system(size: 44))
            Text("スクリーンタイムの許可が必要です")
                .font(.title2).bold()
                .multilineTextAlignment(.center)
            Text("Hushがアプリをブロックするために、\niOSのスクリーンタイム許可が必要です。")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("※アプリの使用履歴を保存・送信しません。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 24)
    }

    private var buttonArea: some View {
        VStack(spacing: 12) {
            if store.isLastPage {
                Button {
                    store.send(.allowScreenTimeTapped)
                } label: {
                    HStack {
                        if store.isRequestingScreenTime {
                            ProgressView().padding(.trailing, 6)
                        }
                        Text("スクリーンタイムを許可する")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.isRequestingScreenTime)

                Button("あとで") {
                    store.send(.skipTapped)
                }
                .buttonStyle(.bordered)
            } else {
                HStack(spacing: 12) {
                    Button("スキップ") {
                        store.send(.skipTapped)
                    }
                    .buttonStyle(.bordered)

                    Button("次へ") {
                        store.send(.nextTapped)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
