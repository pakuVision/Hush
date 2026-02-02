# Architecture Rules

This project strictly follows The Composable Architecture (TCA).

- SwiftUI Views are a function of State.
  
- Views may send Actions but must not contain business logic.
  
- Reducers are the only place where state mutations occur.
  
- Reducers must be pure and synchronous.
  
- Side effects must be implemented as Effects using `.run`.
  
- Dependencies must be accessed using `@Dependency` wrapper.
  
- State is the single source of truth for the entire feature.

---

# View Rules

- Views must never perform data fetching directly.
  
- Views must not contain async business logic.
  
- Use `.task` modifier to send task actions on appear.
  
- Views must not mutate state directly.
  
- Avoid `onAppear` for logic; prefer `.task`.
  
- Views must be fully driven by State.

---

# Reducer Rules (Critical)

Reducers must remain pure and synchronous.

- Never use `await` inside reducer cases.
  
- Never call async functions directly from reducers.
  
- Async work must be wrapped inside `.run`.
  
- Results of async work must be returned via actions.
  
- Reducers are responsible only for state transitions.

**Example:**
```swift
// ✅ Correct: Effect with .run
// ✅ 올바른 방법: .run을 사용한 Effect
case .fetchData:
  return .run { send in
    let data = try await apiClient.fetch()
    await send(.dataLoaded(data))
  }

// ❌ Wrong: Async in reducer
// ❌ 잘못된 방법: Reducer 안에서 async 사용
case .fetchData:
  let data = await apiClient.fetch() // ❌ Never do this!
  state.data = data
  return .none
```

---

# Side Effects & Dependencies

- All side effects must be implemented via `.run`.
  
- Dependencies must be injected using `@Dependency` wrapper.
  
- No singleton managers. Use dependency injection instead.
  
- Reducers must not directly access external services.
  
- Always handle cancellation using `.cancellable(id:)` for long-running effects.
  > 장시간 실행되는 effect는 항상 `.cancellable(id:)`를 사용하여 취소 가능하게 만드세요

**Example:**
```swift
// Dependency 정의
@DependencyClient
struct LocationClient {
  var startMonitoring: () async throws -> AsyncStream<CLLocation>
  var stopMonitoring: () async -> Void
}

// Reducer에서 사용
@Dependency(\.locationClient) var locationClient

case .startLocationTracking:
  return .run { send in
    for await location in try await locationClient.startMonitoring() {
      await send(.locationUpdated(location))
    }
  }
  .cancellable(id: CancelID.location)
```

---

# Composition & Scope

- Use `Scope` to integrate child features.
  
- Parent reducers compose child reducers using `Scope(state:action:)`.
  
- Child features must be self-contained and independently testable.
  
- Use `ifLet` or `forEach` for optional or collection child states.

---

# Navigation Rules

- Use `@Presents` for optional child state (sheets, alerts, popovers).
  
- Navigation state must be part of parent State.
  
- Never perform navigation outside of state mutations.

**Example:**
```swift
@Reducer
struct ParentFeature {
  @ObservableState
  struct State {
    @Presents var destination: Destination.State?
    // destination이 nil이 아니면 sheet가 표시됨
  }
  
  enum Action {
    case destination(PresentationAction<Destination.Action>)
    case showDestination
  }
  
  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .showDestination:
        state.destination = Destination.State()
        // State 변경만으로 navigation 발생
        return .none
      }
    }
    .ifLet(\.$destination, action: \.destination) {
      Destination()
    }
  }
}
```

---

# Testability

Every reducer must be fully testable using TestStore.

- Reducers must not rely on global state.
  
- All dependencies must be injectable and mockable.
  
- State changes must be deterministic.

**Example:**
```swift
@Test
func testFetchData() async {
  let store = TestStore(initialState: Feature.State()) {
    Feature()
  } withDependencies: {
    // Mock dependency 주입
    $0.apiClient.fetch = { "Mock Data" }
  }
  
  await store.send(.fetchData)
  await store.receive(\.dataLoaded) {
    $0.data = "Mock Data"
  }
}
```

---

# Geofencing-Specific Rules
# 지오펜싱 프로젝트 특화 규칙

- Location updates must be handled via LocationClient dependency.
  
- Geofence state changes must trigger actions, not direct mutations.
  
- Screen activation must be state-driven, not location-callback-driven.
  
- Background location updates must be cancellable effects.

---

# Forbidden Patterns
# 금지된 패턴

- ❌ Do not create ObservableObject ViewModels
  
- ❌ Do not perform async work in Views
  
- ❌ Do not mutate state outside Reducer
  
- ❌ Do not use singletons
  
- ❌ Do not fetch data in initializers
