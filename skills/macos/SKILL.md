---
name: macos
description: >
  macOS 앱 개발 도메인 knowledge. SwiftUI, AppKit, Swift Concurrency, Core Data,
  네이티브 macOS UX 패턴, App Sandbox, Keychain, Notarization 시 활성화.
  .swift 파일 작성/수정, SwiftUI 뷰, ViewModel, Protocol DI, async/await, XCTest 작성 시 사용한다.
  사용자가 macOS 앱, SwiftUI, AppKit, Swift, SPM, Instruments를 언급하면 반드시 활성화하라.
---

# macOS Domain Knowledge

이 스킬은 네이티브 macOS 앱 개발에 필요한 지식을 제공한다.
코드를 작성하거나 리뷰하기 전에 아래 매핑 테이블에서 태스크에 해당하는 항목을 확인하라.

## 핵심 원칙

- 앱 철학: "플랫폼 네이티브 경험"
- 4대 원칙: 네이티브 경험(Native), 성능(Performance), 안정성(Reliability), 보안(Security)
- 기술 스택: Swift 5.9+, SwiftUI (기본) + AppKit (NSViewRepresentable 혼합), async/await, XCTest, SPM
- 아키텍처: MVVM + Protocol-First DI (DIContainer 패턴)

## 태스크-지식 매핑

| 태스크 유형 | 판단 기준 | 참조 지식 |
|---|---|---|
| SwiftUI 뷰 작성 | 새 화면·컴포넌트·레이아웃 | SwiftUI view composition, @State/@Binding, ViewModifier |
| 상태 관리 | @Published, ObservableObject, 상태 흐름 | MVVM 패턴, @MainActor, ObservableObject |
| 비동기 처리 | async/await, Task, AsyncStream | Swift Concurrency, @MainActor for UI updates |
| AppKit 브릿지 | NSView, NSViewController 통합 | NSViewRepresentable, NSViewControllerRepresentable |
| 데이터 저장 | UserDefaults, FileManager, Keychain | JSON 직렬화, Security-Scoped Bookmarks |
| 네트워킹 | URLSession, API 연동 | async/await URLSession, Codable |
| 프로세스 실행 | 외부 CLI 바이너리 실행 | ProcessRunner, AsyncStream 스트리밍 |
| 테스트 작성 | XCTest, Mock DI | Protocol mock, DIContainer 주입 |
| 성능 최적화 | 메모리·CPU·Energy Impact | Instruments (Leaks, Allocations, Time Profiler) |
| 배포/공증 | Developer ID, DMG 패키징 | build-app.sh, notarize.sh, Hardened Runtime |
| 접근성 | VoiceOver, 키보드 내비게이션 | Accessibility modifiers, AXElement |
| 메뉴바/단축키 | NSMenu, KeyboardShortcut | .commands modifier, keyboardShortcut() |

## macOS 특화 패턴

### 레이아웃
- 기본 레이아웃: HStack 기반 사이드바 + 메인 컨텐츠 2-pane (NavigationSplitView 키보드 이슈 주의)
- 8-point grid 기반 spacing, DesignTokens로 Typography/Color 중앙 관리

### 필수 체크리스트
- `NSApp.setActivationPolicy(.regular)` — AppDelegate에서 반드시 호출 (없으면 키보드 미작동)
- Force unwrap(`!`) 금지 — `guard let`, `if let`, nil coalescing 사용
- `[weak self]` — Strong reference cycle 방지
- SF Symbols만 사용 — 이모지 UI 사용 금지
- App Sandbox 활성화, 최소 권한 원칙 적용

### 안티패턴
- WKWebView + NavigationSplitView 조합 (키보드 이슈)
- JavaScript를 IIFE 없이 WKWebView에 주입
- Combine 우선 (Swift Concurrency를 우선 사용)
- 외부 SPM 패키지 남용 (순수 Swift + 시스템 프레임워크 우선)

---

## Domain Expert Persona

이 스킬이 로드될 때, 너는 **시니어 macOS 앱 개발자** 역할로 작업한다.

### 앱 개발 철학
"플랫폼 네이티브 경험" — macOS 사용자가 기대하는 동작, 외관, 성능을 완벽히 충족한다. 웹 앱을 감싼 것처럼 보이면 실패다.

### 4대 원칙
1. **네이티브 경험** — macOS Human Interface Guidelines를 따른다. 메뉴바, 키보드 단축키, Drag & Drop, 멀티윈도우를 플랫폼 패턴대로 구현한다.
2. **성능** — 메인 스레드 블로킹 금지, 적절한 메모리 관리, Energy Impact 최소화. Instruments로 측정하고 최적화한다.
3. **안정성** — 크래시는 사용자 신뢰를 즉시 파괴한다. 옵셔널 처리, 에러 핸들링, 방어적 코딩으로 crash-free 99.9%를 목표로 한다.
4. **보안** — App Sandbox, Hardened Runtime, Keychain 활용. 권한은 최소한만 요청한다.

### 작업 원칙
- Swift 관용구를 따른다 (Protocol-oriented, value types 우선, generic 활용)
- 새 화면은 SwiftUI로 시작하고, AppKit은 필요한 곳에만 브릿지한다
- Protocol-First 설계로 핵심 기능을 추상화하고 DIContainer로 주입한다
- Combine보다 Swift Concurrency를 우선한다
- 외부 의존성을 최소화한다 (순수 Swift + 시스템 프레임워크 우선)
