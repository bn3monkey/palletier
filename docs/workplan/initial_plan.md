# Palletier - 초기 구현 전략

## 1. 기술 스택

| 항목 | 선택 | 비고 |
| --- | --- | --- |
| Framework | Flutter (Desktop) | Windows 우선, macOS/Linux 확장 가능 |
| 상태관리 | Riverpod | 비동기 CLI 프로세스 관리에 적합 |
| CLI 통신 | dart:io (Process) | stdin/stdout 파이프를 통한 프로세스 제어 |
| 설정 저장 | shared_preferences | CLI 경로, 모델 선택 등 영속 저장 |
| Markdown 렌더링 | flutter_markdown | AI 응답 표시용 |
| 클립보드 (텍스트) | flutter/services (Clipboard) | RGB 코드 텍스트 복사 |
| 클립보드 (PPT 도형) | Win32 API (Platform Channel) | Art::GVML ClipFormat으로 PowerPoint 네이티브 도형 복사 |

---

## 2. 아키텍처 개요

```text
lib/
├── main.dart
├── app.dart
├── models/
│   ├── cli_config.dart          # CLI 설정 모델 (경로, 모델 종류)
│   ├── chat_message.dart        # 대화 메시지 모델
│   └── color_palette.dart       # 색상 팔레트 모델
├── services/
│   ├── cli_service.dart         # CLI 프로세스 관리 (탐지, 실행, 통신)
│   ├── cli_detector.dart        # Auto-detect / Manual-detect 로직
│   ├── auth_service.dart        # Login / Credential 관리
│   ├── palette_parser.dart      # AI 응답에서 색상 데이터 파싱
│   ├── clipboard_service.dart   # RGB 코드 텍스트 클립보드 복사
│   └── gvml_clipboard.dart     # PowerPoint 도형 GVML ZIP 생성 및 클립보드 복사
├── providers/
│   ├── cli_provider.dart        # CLI 연결 상태 Provider
│   ├── chat_provider.dart       # 대화 상태 Provider
│   └── palette_provider.dart    # 팔레트 상태 Provider
├── widgets/
│   ├── cli_connection_panel.dart # CLI 연결 UI (상단 패널)
│   ├── chat_panel.dart          # 대화 영역 (Markdown + 입력)
│   ├── chat_input_bar.dart      # 하단 입력바 (Commit, TextBox, Dropdown)
│   ├── palette_scroll_view.dart # 색상 팔레트 가로 스크롤 영역
│   └── color_box.dart           # 개별 색상 Box + 복사 버튼
└── screens/
    └── home_screen.dart         # 메인 화면 (좌: 팔레트, 우: 대화창)
```

---

## 3. 구현 단계

### Phase 1: 프로젝트 셋업 및 기본 레이아웃

- Flutter Desktop 프로젝트 생성 (Windows 타겟)
- 좌우 분할 레이아웃 구현
  - 오른쪽 대화창 기본 너비 20%
  - 경계 드래그로 너비 조절 가능 (GestureDetector 또는 ResizableWidget)
- 왼쪽 팔레트 영역 스켈레톤

### Phase 2: AI CLI 연결 기능

- **CLI 탐지 로직**
  - Auto-detect: `where` (Windows) / `which` (Unix) 명령으로 CLI 실행 파일 탐색
  - Manual-detect: 파일 탐색기(FilePicker)로 사용자가 직접 경로 지정
- **CLI 프로세스 관리**
  - `Process.start()`로 CLI 프로세스 실행
  - stdin으로 프롬프트 전송, stdout/stderr 스트림 수신
- **설정 영속화**
  - shared_preferences로 CLI 경로, 모델 선택 저장
  - 앱 시작 시 기존 설정 복원
- **상태 관리**
  - 연결 상태 (Activated / Deactivated) 표시
  - Login 상태 관리

### Phase 3: 대화 기능

- **입력 UI**
  - TextBox (너비 80%)
  - Commit 버튼 (위쪽 화살표, 너비 10%)
  - 추천 색상 개수 Dropdown (3/5/7, 너비 10%)
- **프롬프트 구성**
  - 사용자 입력 + 색상 개수를 포함한 프롬프트 생성
  - AI에게 구조화된 색상 데이터(JSON 등)를 요청하는 시스템 프롬프트 설계
- **응답 처리**
  - AI 스트리밍 응답을 Markdown으로 렌더링
  - 응답에서 색상 데이터(HEX/RGB) 파싱

### Phase 4: 색상 팔레트 표시

- **Color Box 위젯**
  - 상단 80%: 해당 색상으로 채워진 Container
  - 하단 20%: 3등분 버튼 Row
- **복사 기능**
  - RGB 코드 텍스트 클립보드 복사 (flutter/services Clipboard)
  - 무테두리 정사각형 PowerPoint 도형 클립보드 복사 (Art::GVML ClipFormat)
  - 무테두리 원형 PowerPoint 도형 클립보드 복사 (Art::GVML ClipFormat)
  - GVML ZIP을 Dart에서 동적 생성 → Platform Channel → Win32 SetClipboardData
- **가로 스크롤 뷰**
  - ListView.builder (scrollDirection: Axis.horizontal)

### Phase 5: 통합 및 마무리

- 전체 흐름 통합 테스트 (CLI 연결 → 입력 → 응답 → 팔레트 표시 → 복사)
- 에러 처리 (CLI 미연결 시 안내, 파싱 실패 시 폴백)
- UI 다듬기 (로딩 상태, 애니메이션)

---

## 4. 핵심 설계 결정

### 4.1 CLI 통신 방식

CLI 프로세스를 장기 실행(long-running)으로 유지하며 stdin/stdout 파이프로 통신한다.
요청마다 프로세스를 새로 생성하지 않아 오버헤드를 줄인다.

### 4.2 AI 응답 파싱 전략

AI에게 색상 정보를 JSON 블록으로 반환하도록 프롬프트를 설계한다.
응답 JSON에는 **왼쪽 팔레트 영역에 표시할 색상 데이터**와 **오른쪽 대화창에 표시할 설명(description)**이 모두 포함되어야 한다.

```json
{
  "description": "따뜻한 석양 느낌의 팔레트입니다. 주황과 붉은 계열을 중심으로 구성했으며, 보조색으로 하늘색을 배치하여 시각적 대비를 주었습니다.",
  "colors": [
    {
      "name": "Sunset Orange",
      "hex": "#FF6B35",
      "r": 255,
      "g": 107,
      "b": 53,
      "description": "메인 액센트 색상. 따뜻하고 에너지 있는 느낌을 줍니다."
    },
    {
      "name": "Deep Sky",
      "hex": "#1E90FF",
      "r": 30,
      "g": 144,
      "b": 255,
      "description": "보조 색상. 주황과의 보색 대비로 시각적 균형을 잡아줍니다."
    }
  ]
}
```

| 필드 | 표시 위치 | 용도 |
| --- | --- | --- |
| `description` (최상위) | 오른쪽 대화창 | 전체 팔레트에 대한 설명을 Markdown으로 렌더링 |
| `colors[].hex`, `colors[].r/g/b` | 왼쪽 팔레트 | Color Box 색상 표시 및 클립보드 복사 |
| `colors[].name` | 왼쪽 팔레트 | Color Box 내 색상 이름 표시 |
| `colors[].description` | 오른쪽 대화창 | 개별 색상의 선정 이유/용도 설명 |

Markdown 응답 중 JSON 코드 블록을 정규식으로 추출하여 파싱한다.

### 4.3 PowerPoint 도형 클립보드 복사 (Art::GVML ClipFormat)

PowerPoint에 **편집 가능한 네이티브 도형 오브젝트**로 붙여넣기 위해
`Art::GVML ClipFormat` 클립보드 포맷을 사용한다.

**GVML ZIP 구조** (역분석 완료, `data/circle_powerpoint.zip`, `data/rectangle_powerpoint.zip` 참조):

```text
├── [Content_Types].xml              ← 고정
├── _rels/.rels                      ← 고정
└── clipboard/
    ├── drawings/
    │   ├── drawing1.xml             ← 동적 생성 (도형 타입, 색상, 크기)
    │   └── _rels/drawing1.xml.rels  ← 고정
    └── theme/theme1.xml             ← 고정 (기본 Office 테마)
```

**drawing1.xml에서 변경되는 부분은 3곳뿐**:

| 변경점 | XML 속성 | 사각형 값 | 원 값 |
| --- | --- | --- | --- |
| 도형 타입 | `<a:prstGeom prst="...">` | `rect` | `ellipse` |
| 배경 색상 | `<a:srgbClr val="..."/>` | HEX 코드 (예: `FF6B35`) | HEX 코드 |
| 크기 | `<a:ext cx="..." cy="..."/>` | 너비 ≠ 높이 가능 | 너비 = 높이 (정원) |

**구현 흐름**:

```text
Dart: buildGvmlZip(shapeType, hexColor, size)
  → 고정 파일 4개 + drawing1.xml 템플릿 치환 → ZIP 바이트 생성
  → MethodChannel("palletier/clipboard")
    → C++ (Win32):
        RegisterClipboardFormatA("Art::GVML ClipFormat")
        OpenClipboard → EmptyClipboard
        GlobalAlloc + memcpy(zipBytes)
        SetClipboardData(formatId, hGlobal)
        CloseClipboard
```

상세 분석은 `docs/architecture/powerpoint_clipformat.md` 참조.

---

## 5. 의존 패키지 (예상)

| 패키지 | 용도 |
| --- | --- |
| flutter_riverpod | 상태관리 |
| shared_preferences | 설정 영속 저장 |
| flutter_markdown | AI 응답 Markdown 렌더링 |
| file_picker | Manual-detect 시 파일 선택 |
| archive (dart) | GVML ZIP 생성 (메모리 내 ZIP 패킹) |
| Win32 Platform Channel (자체 구현) | Art::GVML ClipFormat 클립보드 복사 |
