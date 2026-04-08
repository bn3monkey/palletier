# PowerPoint 도형 클립보드 포맷 (Art::GVML ClipFormat) 조사 결과

## 1. 배경

Palletier 앱에서 추천된 색상을 PowerPoint에 **편집 가능한 네이티브 도형 오브젝트**로 붙여넣기 위해,
PowerPoint의 클립보드 포맷을 역분석하였다.

---

## 2. PowerPoint 클립보드 포맷 종류

PowerPoint에서 도형을 복사하면 클립보드에 다음 포맷이 동시에 등록된다:

| 포맷 | 타입 | 붙여넣기 결과 |
| --- | --- | --- |
| **`Art::GVML ClipFormat`** | 커스텀 등록 포맷 | **편집 가능한 네이티브 도형** |
| `PowerPoint 12.0 Internal Shapes` | 커스텀 (비공개) | 내부 전용 |
| `PowerPoint 14.0 Slides Package` | 커스텀 (비공개) | 내부 전용 |
| `CF_ENHMETAFILE` | 표준 (EMF) | 이미지로 붙음 (Ctrl+Shift+G x2로 도형 변환 가능) |
| `CF_BITMAP` / `PNG` | 표준 (래스터) | 이미지로 붙음 |

**`Art::GVML ClipFormat`** 만으로 PowerPoint에 네이티브 도형 붙여넣기가 가능하다.
이 포맷은 Office 공통 포맷으로 Word, Excel에서도 인식된다.

---

## 3. GVML ZIP 구조

GVMLClipboardUtils를 사용하여 PowerPoint에서 복사한 도형의 클립보드 데이터를 추출하였다.
(`data/circle_powerpoint.zip`, `data/rectangle_powerpoint.zip`)

### 3.1 파일 트리

```text
├── [Content_Types].xml
├── _rels/
│   └── .rels
└── clipboard/
    ├── drawings/
    │   ├── drawing1.xml
    │   └── _rels/
    │       └── drawing1.xml.rels
    └── theme/
        └── theme1.xml
```

### 3.2 각 파일의 역할과 내용

#### `[Content_Types].xml` (고정)

MIME 타입 선언. 원/사각형 모두 동일.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels"
    ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml"
    ContentType="application/xml"/>
  <Override PartName="/clipboard/drawings/drawing1.xml"
    ContentType="application/vnd.openxmlformats-officedocument.drawing+xml"/>
  <Override PartName="/clipboard/theme/theme1.xml"
    ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>
</Types>
```

#### `_rels/.rels` (고정)

루트 관계 파일. drawing1.xml을 가리킨다.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/drawing"
    Target="clipboard/drawings/drawing1.xml"/>
</Relationships>
```

#### `clipboard/drawings/_rels/drawing1.xml.rels` (고정)

drawing1.xml에서 theme1.xml을 참조.

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1"
    Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/theme"
    Target="../theme/theme1.xml"/>
</Relationships>
```

#### `clipboard/theme/theme1.xml` (고정)

기본 Office 테마 정의 (색상 스킴, 폰트 스킴). 내용이 길지만 원/사각형 모두 동일하며 변경 불필요.
`<a:clipboardTheme>` 루트 요소 아래에 색상 스킴(`<a:clrScheme name="Office">`)과
폰트 스킴(`<a:fontScheme name="Office">`)이 정의되어 있다.

#### `clipboard/drawings/drawing1.xml` (동적 생성 대상)

**핵심 파일.** 도형의 형태, 색상, 크기가 정의된다.

---

## 4. drawing1.xml 상세 분석

### 4.1 원 (ellipse) - circle_powerpoint.zip

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
  <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas">
    <lc:lockedCanvas xmlns:lc="http://schemas.openxmlformats.org/drawingml/2006/lockedCanvas">

      <!-- 그룹 속성: 전체 캔버스 크기 -->
      <a:nvGrpSpPr>
        <a:cNvPr id="0" name=""/>
        <a:cNvGrpSpPr/>
      </a:nvGrpSpPr>
      <a:grpSpPr>
        <a:xfrm>
          <a:off x="0" y="0"/>
          <a:ext cx="1519310" cy="1519310"/>       <!-- 캔버스 크기 (EMU) -->
          <a:chOff x="2644726" y="647114"/>        <!-- 원본 슬라이드 내 위치 -->
          <a:chExt cx="1519310" cy="1519310"/>     <!-- 원본 도형 크기 -->
        </a:xfrm>
      </a:grpSpPr>

      <!-- 도형 본체 -->
      <a:sp>
        <a:nvSpPr>
          <a:cNvPr id="6" name="타원 5">
            <a:extLst>
              <a:ext uri="{FF2B5EF4-FFF2-40B4-BE49-F238E27FC236}">
                <a16:creationId xmlns:a16="http://schemas.microsoft.com/office/drawing/2014/main"
                  id="{D2A9B58D-54B3-9D32-424D-047CA472DFD6}"/>
              </a:ext>
            </a:extLst>
          </a:cNvPr>
          <a:cNvSpPr/>
        </a:nvSpPr>
        <a:spPr>
          <a:xfrm>
            <a:off x="2644726" y="647114"/>
            <a:ext cx="1519310" cy="1519310"/>     <!-- ★ cx = cy → 정원 -->
          </a:xfrm>
          <a:prstGeom prst="ellipse">              <!-- ★ 도형 타입: ellipse -->
            <a:avLst/>
          </a:prstGeom>
          <a:solidFill>
            <a:srgbClr val="FF0000"/>              <!-- ★ 배경 색상: 빨강 -->
          </a:solidFill>
          <a:ln><a:noFill/></a:ln>                 <!-- 무테두리 -->
        </a:spPr>

        <!-- 텍스트 속성 (비어있음, boilerplate) -->
        <a:txSp>...</a:txSp>

        <!-- 스타일 참조 (테마 기본값) -->
        <a:style>...</a:style>
      </a:sp>

    </lc:lockedCanvas>
  </a:graphicData>
</a:graphic>
```

### 4.2 사각형 (rect) - rectangle_powerpoint.zip

원과의 **차이점만** 표시:

```xml
<a:ext cx="1406769" cy="1294228"/>     <!-- 너비 ≠ 높이 (직사각형) -->
<a:prstGeom prst="rect">              <!-- ★ 도형 타입: rect -->
<a:srgbClr val="FF0000"/>             <!-- 배경 색상 (동일) -->
```

### 4.3 변경 포인트 요약

원과 사각형에서 실제로 달라지는 부분은 **3곳**:

| # | XML 요소 | 설명 | 예시 값 |
| --- | --- | --- | --- |
| 1 | `<a:prstGeom prst="...">` | 도형 프리셋 타입 | `rect`, `ellipse` |
| 2 | `<a:srgbClr val="..."/>` | 채우기 색상 (HEX, # 없이) | `FF0000`, `1E90FF` |
| 3 | `<a:ext cx="..." cy="..."/>` | 도형 크기 (EMU 단위) | 원: cx=cy, 사각형: cx≠cy 가능 |

**EMU (English Metric Units)**: 914400 EMU = 1 inch. 1519310 EMU ≈ 1.66 inch ≈ 4.22 cm.

나머지 요소(txSp, style, nvSpPr 등)는 기본값 boilerplate로 고정 사용 가능하다.

---

## 5. 구현 전략

### 5.1 템플릿 방식

고정 파일 4개는 앱 asset에 내장하고, `drawing1.xml`만 템플릿에서 동적 생성한다.

```dart
String buildDrawingXml({
  required String shapeType,  // "rect" 또는 "ellipse"
  required String hexColor,   // "FF6B35" (# 제외, 6자리)
  int widthEmu = 1500000,     // 기본 약 4.17cm
  int heightEmu = 1500000,
}) {
  // drawing1.xml 템플릿에서 3곳 치환
}
```

### 5.2 클립보드 등록 (Win32 Platform Channel)

```cpp
// Flutter Windows Plugin (C++)
void SetGvmlClipboard(const std::vector<uint8_t>& zipBytes) {
    UINT formatId = RegisterClipboardFormatA("Art::GVML ClipFormat");
    if (OpenClipboard(nullptr)) {
        EmptyClipboard();
        HGLOBAL hGlobal = GlobalAlloc(GMEM_MOVEABLE, zipBytes.size());
        if (hGlobal) {
            void* pData = GlobalLock(hGlobal);
            memcpy(pData, zipBytes.data(), zipBytes.size());
            GlobalUnlock(hGlobal);
            SetClipboardData(formatId, hGlobal);
        }
        CloseClipboard();
    }
}
```

### 5.3 Dart → C++ 호출

```dart
static const _channel = MethodChannel('palletier/clipboard');

Future<void> copyPowerPointShape({
  required String shapeType,
  required String hexColor,
}) async {
  final zipBytes = _buildGvmlZip(shapeType, hexColor);
  await _channel.invokeMethod('setGvmlClipboard', zipBytes);
}
```

---

## 6. 참고 자료

- 역분석 데이터: `data/circle_powerpoint.zip`, `data/rectangle_powerpoint.zip`
- GVMLClipboardUtils: https://github.com/rohitagrawalla/GVMLClipboardUtils
- DrawingML 사양: ECMA-376 Part 1, 20장 (DrawingML - Framework)
- EMU 단위: 914400 EMU = 1 inch = 2.54 cm
