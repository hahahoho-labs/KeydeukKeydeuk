# AGENTS.md

## 프로젝트 개요
KeydeukKeydeuk는 macOS용 단축키 치트시트(오버레이) MVP 프로젝트다.

핵심 목표:
- Clean Architecture 원칙 유지
- SwiftUI + MVVM 적용
- 기능 단위 분리(FSD 정신) 반영
- MVP는 내장 JSON 카탈로그 기반으로 빠르게 개발
- 이후 AX 자동 추출/StoreKit 확장을 고려한 구조 유지

현재 UX 방향(우선순위):
1. 최초 실행 시 온보딩 화면으로 권한/초기 설정 진행
2. 온보딩 완료 후에는 StatusBar 아이콘 중심으로 앱 사용
3. StatusBar 아이콘 좌클릭(한 손가락 클릭) 시 오버레이 표시 트리거
4. StatusBar 아이콘 우클릭(트랙패드 두 손가락 클릭) 시 메뉴 드롭다운
5. 설정 창은 후속 단계에서 구현

## 아키텍처 원칙
- Domain은 정책/규칙만 가진다.
- Domain은 SwiftUI, AppKit, AX API, UserDefaults, StoreKit 같은 구현 디테일을 모른다.
- UseCase(Application)는 시나리오를 조합한다.
- UI는 UseCase만 호출하고 상태를 표시한다.
- Platform/Data는 Domain Protocol(Port)을 구현한다.

## 현재 폴더 구조(단일 타겟)
```text
KeydeukKeydeuk/
  App/
    AppContainer.swift
    AppOrchestrator.swift
    KeydeukKeydeukApp.swift
  Domain/
    Entities/
    Policies/
    Protocols/
  Application/
    UseCases/
  Data/
    Repositories/
    Stores/
    Resources/
  Platform/
    Input/
    Permissions/
    AppContext/
    Overlay/
  UI/
    Overlay/
    Onboarding/
    Settings/
  Shared/
    Foundation/
```

## 레이어 책임
- App
  - DI 조립, 앱 부트스트랩, 유스케이스 오케스트레이션
- Domain
  - Entity/Value Object, 정책(Policy), 포트(Protocol)
- Application
  - 유스케이스(EvaluateActivation, Show/Hide Overlay, LoadShortcuts, LoadPreferences, UpdatePreferences, OpenAccessibilitySettings, GetAccessibilityPermissionState)
- Data
  - 저장소/설정 저장 구현(JSON, UserDefaults)
- Platform
  - macOS 시스템 연동(NSEvent, AX 권한, 전면 앱 감지, 오버레이 호스트, 시스템 설정 열기, StatusBar 아이콘/메뉴)
- UI
  - SwiftUI View + ViewModel(MVVM), 온보딩 액션/트리거 설정 UI

## 정적 의존성(컴파일 타임)
```mermaid
flowchart LR
  UI["UI (SwiftUI + MVVM)"] --> APP["Application (UseCases)"]
  APP --> DOM["Domain (Entities/Policies/Protocols)"]

  DATA["Data Implementations"] --> DOM
  PLATFORM["Platform Implementations"] --> DOM

  BOOT["App/DI Container"] --> UI
  BOOT --> APP
  BOOT --> DATA
  BOOT --> PLATFORM
```

의존성 규칙:
- `UI -> Application -> Domain`
- `Data/Platform -> Domain` (Protocol 구현)
- Domain은 바깥 레이어에 의존하지 않는다.

## 런타임 제어 흐름(입력 -> 오버레이)
```mermaid
sequenceDiagram
  participant ES as Platform.EventSource
  participant EA as UseCase.EvaluateActivation
  participant SS as UseCase.ShowOverlayForCurrentApp
  participant PC as PermissionChecker
  participant AC as AppContextProvider
  participant SR as ShortcutRepository
  participant OP as OverlayPresenter
  participant UI as UI.ViewModel/View

  ES->>EA: KeyEvent 전달
  EA->>EA: ActivationPolicy + Preferences로 판단

  alt activate
    EA->>SS: execute()
    SS->>PC: 접근성 권한 체크
    alt denied/notDetermined
      SS-->>UI: permissionRequired 상태
    else granted
      SS->>AC: 현재 전면 앱 조회
      SS->>SR: bundleID로 단축키 로드
      alt catalog 있음
        SS->>OP: show(catalog, app)
        OP-->>UI: 오버레이 표시
      else catalog 없음
        SS-->>UI: noCatalog 상태
      end
    end
  else hide
    EA->>OP: hide()
    OP-->>UI: 오버레이 숨김
  else ignore
    EA-->>ES: no-op
  end
```

## 런타임 제어 흐름(온보딩/설정)
```mermaid
sequenceDiagram
  participant UI as UI.Onboarding/Settings
  participant VM as OverlayViewModel
  participant LP as UseCase.LoadPreferences
  participant GP as UseCase.GetAccessibilityPermissionState
  participant UP as UseCase.UpdatePreferences
  participant OA as UseCase.OpenAccessibilitySettings
  participant PS as PreferencesStore
  participant PG as PermissionGuide

  UI->>VM: 화면 진입
  VM->>LP: 현재 Preferences 로드
  LP->>PS: load()
  PS-->>VM: Preferences 반환
  VM->>GP: 접근성 권한 상태 확인
  VM-->>UI: 토글/핫키 프리셋 상태 반영

  UI->>VM: 핫키/자동숨김 값 변경
  VM->>UP: execute(updatedPreferences)
  UP->>PS: save(...)
  PS-->>VM: 저장 완료

  UI->>VM: 접근성 설정 열기 버튼 탭
  VM->>OA: execute()
  OA->>PG: openAccessibilitySettings()

  UI->>VM: Finish Setup 탭
  VM->>GP: 권한 상태 재확인
  VM->>UP: hasCompletedOnboarding=true 저장
```

## 런타임 제어 흐름(StatusBar)
```mermaid
sequenceDiagram
  participant SB as Platform.StatusBarController
  participant VM as OverlayViewModel
  participant SO as UseCase.ShowOverlayForCurrentApp

  SB->>VM: 좌클릭(primary click)
  VM->>SO: requestShow()
  SO-->>VM: shown / needsPermission / noCatalog

  SB->>SB: 우클릭(두 손가락 클릭)
  SB-->>User: Settings / Quit 메뉴 표시
```

## 현재 MVP 범위
- 접근성 권한 상태 확인
- 권한 온보딩에서 시스템 접근성 설정 열기 버튼 제공
- 권한 요청 프롬프트 트리거(AX prompt) + 상태 재확인
- 글로벌 핫키 기반 트리거
- 현재 활성 앱 감지
- 오버레이 표시/숨김
- 검색 가능한 단축키 리스트 표시
- 핫키 프리셋/자동숨김 토글 설정 저장(UserDefaults)
- 내장 JSON 카탈로그(`Data/Resources/shortcuts_catalog.json`) 기반 단축키 로드
- 온보딩 완료 후 StatusBar 중심 동작(좌클릭 트리거, 우클릭 메뉴)

## 확장 포인트
- AX 기반 자동 추출 Repository 추가
- Overlay를 실제 NSWindow 레벨/포지션 제어로 확장
- BillingService 구현(StoreKit 결제/구독)
- Cache 계층 도입
- StatusBar의 Settings 메뉴에서 독립 설정 창 오픈(현재 placeholder)

## 구현 시 주의사항
- ViewModel이 Platform 구현체를 직접 참조하지 않기
- Domain 타입에 UI/AppKit 타입 섞지 않기
- UseCase가 정책 대신 메커니즘 코드를 직접 품지 않기
- 신규 기능 추가 시 먼저 Domain Port를 정의하고, 이후 Platform/Data에서 구현하기
