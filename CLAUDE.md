# Project Overview
# 프로젝트 개요

**Hush**: Location-based Screen Time enforcement app
**Hush**: 위치 기반 스크린 타임 강제 실행 앱

## Core Concept
## 핵심 컨셉

When user enters a registered geofence area (200m radius):
- Automatically blocks pre-configured apps or categories using Screen Time API
- Blocks remain active while inside the geofence
- Automatically unblocks when user exits the area

사용자가 등록된 지오펜스 영역(반경 200m)에 진입하면:
- 미리 설정한 앱 또는 카테고리를 Screen Time API로 자동 차단
- 지오펜스 내부에 있는 동안 차단 유지
- 영역을 벗어나면 자동으로 차단 해제

## Key Features (MVP)
## 핵심 기능 (MVP)

1. Geofence registration (location + radius)
   // 지오펜스 등록 (위치 + 반경)
   
2. App/Category selection for blocking
   // 차단할 앱/카테고리 선택
   
3. Background location monitoring
   // 백그라운드 위치 모니터링
   
4. Automatic Screen Time control
   // 자동 스크린 타임 제어

---

## TCA Architecture Folder Rules (Very Important)

This project strictly follows **Feature-oriented folder structure** based on
The Composable Architecture (TCA).

Do NOT suggest or generate MVVM style folder structures such as:
- Views/
- ViewModels/
- Models/

These are considered incorrect for this project.

### Core Principle

In TCA, a Feature is a self-contained unit that includes:

- State
- Action
- Reducer
- View

All of these MUST live together in the same Feature folder.

### Required Folder Structure

App structure must look like this:

App/
├── AppFeature/
├── Core/
├── Shared/
├── Features/

### Feature Folder Rules

Each Feature must contain:

Features/
 ├── Diary/
 │    ├── DiaryFeature.swift
 │    ├── DiaryView.swift
 │    ├── Components/
 │    └── DiaryCoreData.swift (if needed)
 │
 ├── Habit/
 ├── Mood/
 ├── Tracker/
 └── Settings/

### Important Rules

1. Do NOT separate View / ViewModel / Model folders.
2. Do NOT place Reducers in a separate folder.
3. Each Feature owns its View, Reducer, and internal data logic.
4. CoreData or data logic specific to a Feature lives inside that Feature.
5. Shared UI components go to `Shared/Components`.
6. Dependency clients go to `Core/Clients`.
7. State in TCA should consist only of pure values. Avoid storing side effects, reference types, or non-deterministic data in state.

### Philosophy

TCA is read by **Feature**, not by UI layer.

When suggesting code or structure, always think:
"Which Feature does this belong to?"
Never:
"Which View or ViewModel does this belong to?"

