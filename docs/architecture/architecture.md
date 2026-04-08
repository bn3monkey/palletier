# Palletier - 아키텍처 설계

## 1. 프로젝트 디렉토리 구조

```text
palletier/
├── app/                             ← Flutter Desktop 프로젝트 루트
│   ├── lib/
│   │   ├── main.dart                # 앱 진입점
│   │   ├── app.dart                 # MaterialApp 설정, 라우팅
│   │   ├── models/                  # 데이터 모델
│   │   ├── services/                # 비즈니스 로직 (CLI, 클립보드 등)
│   │   ├── providers/               # Riverpod 상태관리
│   │   ├── widgets/                 # 재사용 위젯
│   │   └── screens/                 # 화면 단위 위젯
│   ├── windows/
│   │   └── runner/
│   │       └── gvml_clipboard_plugin.cpp   # Win32 클립보드 Platform Channel
│   ├── assets/
│   │   └── gvml_templates/          # GVML ZIP 고정 파일 (4개)
│   │       ├── content_types.xml
│   │       ├── rels.xml
│   │       ├── drawing_rels.xml
│   │       └── theme1.xml
│   ├── pubspec.yaml
│   └── ...
├── data/                            ← 역분석 원본 데이터
│   ├── circle_powerpoint.zip
│   └── rectangle_powerpoint.zip
└── docs/
    ├── requirement/
    ├── architecture/
    └── workplan/
```

---

## 2. 레이어 아키텍처

```text
┌─────────────────────────────────────────────────────────┐
│                      Screens                            │
│  HomeScreen (좌: 팔레트, 우: 대화창)                       │
├─────────────────────────────────────────────────────────┤
│                      Widgets                            │
│  CliConnectionPanel │ ChatPanel │ PaletteScrollView     │
│  ChatInputBar       │ ColorBox                          │
├─────────────────────────────────────────────────────────┤
│                    Providers (Riverpod)                  │
│  CliProvider │ ChatProvider │ PaletteProvider            │
├─────────────────────────────────────────────────────────┤
│                     Services                            │
│  CliService │ CliDetector │ AuthService                  │
│  PaletteParser │ ClipboardService │ GvmlClipboard       │
├─────────────────────────────────────────────────────────┤
│                      Models                             │
│  CliConfig │ ChatMessage │ ColorPalette                  │
├─────────────────────────────────────────────────────────┤
│                  Platform Channel                       │
│  palletier/clipboard → Win32 GVML ClipFormat API        │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 모델 설계

### 3.1 CliConfig

```dart
enum CliModel { geminiCli, claudeCode }
enum CliStatus { disconnected, connected, authenticated }

class CliConfig {
  final CliModel model;
  final String? executablePath;
  final CliStatus status;
}
```

### 3.2 ChatMessage

```dart
enum MessageRole { user, assistant }

class ChatMessage {
  final MessageRole role;
  final String content;          // 원본 텍스트 (사용자 입력 또는 AI 전체 응답)
  final DateTime timestamp;
}
```

### 3.3 ColorPalette

```dart
class PaletteColor {
  final String name;             // "Sunset Orange"
  final String hex;              // "#FF6B35"
  final int r, g, b;
  final String description;      // "메인 액센트 색상. 따뜻하고..."
}

class ColorPalette {
  final String description;      // 전체 팔레트 설명
  final List<PaletteColor> colors;
}
```

---

## 4. 서비스 설계

### 4.1 CliService — CLI 프로세스 관리

```text
CliService
├── detect(CliModel) → Future<String?>        # Auto-detect: where/which로 경로 탐색
├── setPath(String path) → void               # Manual-detect: 직접 경로 지정
├── start() → Future<void>                    # Process.start()로 장기 실행 프로세스 시작
├── send(String prompt) → Stream<String>      # stdin 전송, stdout 스트림 반환
├── login() → Future<bool>                    # Credential 연결
└── dispose() → void                          # 프로세스 종료
```

**CLI 프로세스 생명주기:**

```text
[Disconnected] ──detect/setPath──→ [Path Set] ──start──→ [Connected] ──login──→ [Authenticated]
       ↑                                                       │
       └────────────────────── dispose ─────────────────────────┘
```

- 프로세스는 장기 실행(long-running)으로 유지하며 stdin/stdout 파이프로 통신
- stdout 스트림은 `Stream<String>`으로 노출하여 UI에서 실시간 렌더링

### 4.2 PaletteParser — AI 응답 파싱

```text
PaletteParser
└── parse(String response) → ColorPalette?
```

AI 응답에서 JSON 코드 블록을 정규식으로 추출 후 `ColorPalette`로 변환한다.

**파싱 흐름:**

```text
AI 응답 (Markdown + JSON)
  → RegExp(r'```json\s*([\s\S]*?)```') 로 JSON 블록 추출
  → jsonDecode → ColorPalette.fromJson()
```

**AI 응답 JSON 스키마:**

```json
{
  "description": "전체 팔레트 설명",
  "colors": [
    {
      "name": "색상 이름",
      "hex": "#RRGGBB",
      "r": 0, "g": 0, "b": 0,
      "description": "개별 색상 설명"
    }
  ]
}
```

### 4.3 GvmlClipboard — PowerPoint 도형 클립보드 복사

```text
GvmlClipboard
├── copyRectangle(String hexColor) → Future<void>
└── copyEllipse(String hexColor) → Future<void>
```

**내부 흐름:**

```text
1. drawing1.xml 템플릿 생성
   - shapeType: "rect" 또는 "ellipse"
   - hexColor: "FF6B35" (# 제외)
   - size: 고정값 (원: cx=cy=1500000 EMU, 사각형: cx=cy=1500000 EMU)

2. ZIP 패킹 (archive 패키지, 메모리 내)
   ├── [Content_Types].xml    ← asset에서 로드
   ├── _rels/.rels            ← asset에서 로드
   ├── clipboard/drawings/drawing1.xml        ← 동적 생성
   ├── clipboard/drawings/_rels/drawing1.xml.rels  ← asset에서 로드
   └── clipboard/theme/theme1.xml             ← asset에서 로드

3. Platform Channel 호출
   MethodChannel("palletier/clipboard")
     .invokeMethod("setGvmlClipboard", zipBytes)

4. Win32 (C++)
   RegisterClipboardFormatA("Art::GVML ClipFormat")
   OpenClipboard → EmptyClipboard
   GlobalAlloc + memcpy(zipBytes)
   SetClipboardData(formatId, hGlobal)
   CloseClipboard
```

상세 GVML 포맷 분석: [powerpoint_clipformat.md](powerpoint_clipformat.md) 참조.

### 4.4 ClipboardService — 텍스트 클립보드

```text
ClipboardService
└── copyText(String text) → Future<void>   # RGB 코드 복사 ("rgb(255, 107, 53)")
```

Flutter 기본 `Clipboard.setData()` 사용.

---

## 5. Provider 설계 (Riverpod)

### 5.1 의존 관계

```text
CliProvider ←── ChatProvider ←── PaletteProvider
    │                │                 │
    ▼                ▼                 ▼
CliService      CliService        PaletteParser
                PaletteParser
```

### 5.2 각 Provider 역할

| Provider | 상태 | 역할 |
| --- | --- | --- |
| `cliProvider` | `AsyncNotifier<CliConfig>` | CLI 연결 상태 관리, 설정 영속화 (shared_preferences) |
| `chatProvider` | `Notifier<List<ChatMessage>>` | 대화 목록 관리, CLI에 프롬프트 전송 및 응답 수신 |
| `paletteProvider` | `Notifier<ColorPalette?>` | 최신 AI 응답에서 파싱된 팔레트 상태 관리 |

### 5.3 데이터 흐름

```text
[사용자 입력]
    │
    ▼
ChatProvider.send(text, colorCount)
    │
    ├── 1. ChatMessage(role: user) 추가
    ├── 2. 시스템 프롬프트 + 사용자 입력 조합
    ├── 3. CliService.send(prompt) → Stream<String>
    ├── 4. 스트리밍 응답을 ChatMessage(role: assistant)에 누적
    └── 5. 응답 완료 시 PaletteParser.parse() → PaletteProvider 갱신
                │
                ▼
         [왼쪽: ColorBox 렌더링]  +  [오른쪽: Markdown 렌더링]
```

---

## 6. 화면 구성 (Widget Tree)

```text
HomeScreen
├── PaletteScrollView (왼쪽, Expanded)
│   └── ListView.horizontal
│       └── ColorBox * N
│           ├── Container (상단 80%, 색상 채우기)
│           └── Row (하단 20%, 3등분)
│               ├── CopyRgbButton        → ClipboardService.copyText()
│               ├── CopyRectButton       → GvmlClipboard.copyRectangle()
│               └── CopyEllipseButton    → GvmlClipboard.copyEllipse()
│
├── GestureDetector (드래그 핸들, 너비 조절)
│
└── ChatSidePanel (오른쪽, 기본 20% 너비)
    ├── CliConnectionPanel (상단 20%)
    │   ├── Row: [ModelDropdown] [AutoDetectBtn] [ManualDetectBtn] [StatusBadge]
    │   └── Row: [LoginBtn] [CurrentStatusText]
    │
    ├── ChatMessageList (중앙, Expanded, 스크롤)
    │   └── ChatBubble * N
    │       └── MarkdownBody (flutter_markdown)
    │
    └── ChatInputBar (하단)
        └── Row: [TextField 80%] [CommitBtn ↑ 10%] [ColorCountDropdown 10%]
```

---

## 7. Platform Channel 설계

### 7.1 채널 정의

| 채널 이름 | 메서드 | 인자 | 반환 |
| --- | --- | --- | --- |
| `palletier/clipboard` | `setGvmlClipboard` | `Uint8List` (ZIP 바이트) | `bool` (성공 여부) |

### 7.2 Windows 네이티브 구현 위치

```text
app/windows/runner/
├── main.cpp               ← 기존 (Flutter 생성)
├── flutter_window.cpp     ← 기존 (Flutter 생성)
└── gvml_clipboard_plugin.cpp  ← 신규: MethodChannel 핸들러 + Win32 클립보드 API
```

`flutter_window.cpp`에서 MethodChannel을 등록하고,
`gvml_clipboard_plugin.cpp`의 `SetGvmlClipboard()` 함수를 호출한다.

---

## 8. 시스템 프롬프트 설계

AI CLI에 전송할 시스템 프롬프트 구조:

```text
당신은 색상 팔레트 추천 전문가입니다.
사용자가 원하는 느낌을 설명하면, {colorCount}개의 색상으로 구성된 팔레트를 추천해주세요.

반드시 아래 JSON 형식으로 응답하세요:

```json
{
  "description": "팔레트 전체에 대한 설명 (한국어, 2-3문장)",
  "colors": [
    {
      "name": "영문 색상 이름",
      "hex": "#RRGGBB",
      "r": 0-255,
      "g": 0-255,
      "b": 0-255,
      "description": "이 색상을 선택한 이유와 용도 (한국어, 1문장)"
    }
  ]
}
``` (끝)

JSON 블록 앞뒤에 추가 설명을 자유롭게 작성해도 됩니다.
```

---

## 9. 설정 영속화

shared_preferences에 저장하는 키:

| 키 | 타입 | 설명 |
| --- | --- | --- |
| `cli_model` | `String` | 선택된 모델 (`geminiCli` / `claudeCode`) |
| `cli_path` | `String` | CLI 실행 파일 경로 |
| `chat_panel_width_ratio` | `double` | 오른쪽 패널 너비 비율 (기본 0.2) |

---

## 10. 의존 패키지

| 패키지 | 버전 | 용도 |
| --- | --- | --- |
| flutter_riverpod | latest | 상태관리 |
| shared_preferences | latest | 설정 영속 저장 |
| flutter_markdown | latest | AI 응답 Markdown 렌더링 |
| file_picker | latest | Manual-detect 시 파일 선택 다이얼로그 |
| archive | latest | GVML ZIP 메모리 내 생성 |

Platform Channel (자체 C++ 구현):
- `palletier/clipboard` → Win32 `SetClipboardData("Art::GVML ClipFormat")`
