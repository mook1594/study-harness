---
description: |
  spec과 디자인 결정을 기반으로 화면별 HTML/CSS 인터랙티브 목업 생성.
  트리거: /mockup {feature-name}
allowed-tools: Read, Write, Glob, Bash
agent: Sonnet
---

# Mockup - 인터랙티브 목업 생성

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 입력 파일 로드

아래 파일을 모두 읽는다:
- `docs/design/$ARGUMENTS/spec.md`
- `docs/design/$ARGUMENTS/design.md`

파일이 없으면:
- `spec.md` 없음 → "spec 단계를 먼저 완료해 주세요. `/spec $ARGUMENTS`" 안내 후 종료
- `design.md` 없음 → "design-decision 단계를 먼저 완료해 주세요. `/design-decision $ARGUMENTS`" 안내 후 종료

### 2단계: 화면별 목업 생성

spec.md의 화면 목록을 기준으로 각 화면마다 독립 HTML 파일을 생성한다.

**생성 규칙:**
- design.md의 컬러/타이포/간격을 CSS Custom Properties로 `:root`에 정의
- Tailwind CDN 사용: `<script src="https://cdn.tailwindcss.com"></script>`
- Tailwind config `extend`에 design.md 컬러를 주입 (inline script)
- 실제 데이터처럼 보이는 의미 있는 더미 콘텐츠 사용 (lorem ipsum, "텍스트" 등 금지)
- 인터랙션이 필요한 경우 vanilla JS로 최소한만 구현

**파일 생성 위치:**
```
docs/design/$ARGUMENTS/mockup/
  index.html          ← 화면 목록 링크 페이지
  {화면명}.html       ← 화면별 목업
```

**각 HTML 파일 기본 구조:**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>{화면명} — {feature} 목업</title>
  <script src="https://cdn.tailwindcss.com"></script>
  <script>
    tailwind.config = {
      theme: {
        extend: {
          colors: {
            primary: '{design.md primary hex}',
            secondary: '{design.md secondary hex}',
            background: '{design.md background hex}',
            surface: '{design.md surface hex}',
            'text-primary': '{design.md text-primary hex}',
            'text-secondary': '{design.md text-secondary hex}',
            error: '{design.md error hex}',
          }
        }
      }
    }
  </script>
  <style>
    :root {
      --color-primary: {primary hex};
      --color-secondary: {secondary hex};
      --color-background: {background hex};
      --color-surface: {surface hex};
      --color-text-primary: {text-primary hex};
      --color-text-secondary: {text-secondary hex};
      --color-error: {error hex};
      --font-family: '{design.md font}', sans-serif;
      --radius-sm: {sm}px;
      --radius-md: {md}px;
      --radius-lg: {lg}px;
    }
    body { font-family: var(--font-family); }
  </style>
</head>
<body class="bg-background min-h-screen">
  <!-- 목업 콘텐츠 -->
</body>
</html>
```

**index.html 구조:**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <title>{feature} 목업 목록</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="p-8 font-sans">
  <h1 class="text-2xl font-bold mb-4">{feature} 목업</h1>
  <ul class="space-y-2">
    <li><a href="{화면명}.html" class="text-blue-600 underline">{화면명}</a></li>
  </ul>
</body>
</html>
```

### 3단계: 확인 요청

목업 파일 생성 후 사용자에게 확인을 요청한다:

```
✅ 목업 생성 완료

확인 방법:
  open docs/design/$ARGUMENTS/mockup/index.html

생성된 화면:
  - {화면1}: docs/design/$ARGUMENTS/mockup/{화면1}.html
  - {화면2}: docs/design/$ARGUMENTS/mockup/{화면2}.html

목업 확인 후 수정 사항을 알려주시면 반영합니다.
문제없으면 "확인 완료"라고 말씀해 주세요.
```

사용자가 수정 요청하면 해당 HTML 파일을 수정한다.
"확인 완료" 또는 승인 의사를 표하면 다음 단계로 진행.

### 4단계: state.json 업데이트 및 완료 안내

기존 `docs/design/$ARGUMENTS/state.json` 을 읽어 아래 항목만 업데이트한다:
- `completed` 배열에 `"mockup"` 추가 (기존 값 유지)
- `current_step` → `"component"`
- `artifacts.mockup` → `"docs/design/$ARGUMENTS/mockup/"`

완료 안내:
```
✅ mockup 완료 → docs/design/$ARGUMENTS/mockup/

다음 단계: component
  /design-flow $ARGUMENTS   (전체 플로우 계속)
  /component $ARGUMENTS      (component 단계만 실행)
```
