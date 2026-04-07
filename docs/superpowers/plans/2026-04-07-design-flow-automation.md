# Design Flow Automation 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기능 요청부터 Vue/Nuxt 프론트엔드 개발까지 이어지는 디자인 플로우를 6개 개별 스킬 + 1개 오케스트레이터 스킬로 하네스에 통합한다.

**Architecture:** 각 단계(brainstorm → spec → design-decision → mockup → component → tokens)를 독립 SKILL.md 파일로 구현하고, `/design-flow` 오케스트레이터가 `state.json`을 읽어 현재 단계를 파악 후 해당 스킬 로직을 실행한다. 단계별 산출물은 `docs/design/{feature}/` 에 저장되어 다음 단계의 입력으로 자동 주입된다.

**Tech Stack:** Claude Code Skills (SKILL.md), Vue/Nuxt, Tailwind CSS, CSS Custom Properties, TypeScript

---

## 파일 구조

| 파일 | 역할 | 작업 |
|------|------|------|
| `skills/brainstorm/SKILL.md` | 기능 분석 + 질의응답 스킬 | 신규 |
| `skills/spec/SKILL.md` | 기능 스펙 문서 작성 스킬 | 신규 |
| `skills/design-decision/SKILL.md` | 컬러/타이포/간격 결정 스킬 | 신규 |
| `skills/mockup/SKILL.md` | HTML/CSS 인터랙티브 목업 생성 스킬 | 신규 |
| `skills/component/SKILL.md` | Vue SFC 컴포넌트 변환 스킬 | 신규 |
| `skills/tokens/SKILL.md` | 디자인 토큰 추출 스킬 | 신규 |
| `skills/design-flow/SKILL.md` | 전체 플로우 오케스트레이터 스킬 | 신규 |
| `CLAUDE.md` | Vue/Nuxt 디자인 플로우 가이드 추가 | 수정 |
| `install.sh` | 7개 신규 스킬 등록 추가 | 수정 |

---

### Task 1: 스킬 디렉토리 구조 생성

**Files:**
- Create: `skills/brainstorm/`, `skills/spec/`, `skills/design-decision/`, `skills/mockup/`, `skills/component/`, `skills/tokens/`, `skills/design-flow/`

- [ ] **Step 1: 디렉토리 생성**

```bash
mkdir -p skills/brainstorm skills/spec skills/design-decision skills/mockup skills/component skills/tokens skills/design-flow
```

- [ ] **Step 2: 생성 확인**

```bash
ls skills/
```

Expected output:
```
brainstorm  commit  component  design-decision  design-flow  mockup  plan  review  spec  tokens
```

- [ ] **Step 3: 커밋**

```bash
git add skills/
git commit -m "chore: design flow 스킬 디렉토리 구조 생성"
```

---

### Task 2: brainstorm 스킬 작성

기능 요청을 받아 목적, 사용자 시나리오, 제약사항을 질의응답으로 도출하고 `brainstorm.md`와 `state.json`을 저장한다.

**Files:**
- Create: `skills/brainstorm/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/brainstorm/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
---
description: |
  기능 분석 및 브레인스토밍. 기능 요청을 받아 목적, 사용자 시나리오, 제약사항을 도출.
  트리거: /brainstorm {feature-name}, "브레인스토밍"
allowed-tools: Read, Write, Glob, Bash
agent: Sonnet
---

# Brainstorm - 기능 분석

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 이전 작업 확인

`docs/design/$ARGUMENTS/brainstorm.md` 가 존재하면 읽어서 내용을 파악한다.
이미 완료된 경우 "이미 brainstorm이 완료되어 있습니다. 다시 진행할까요?" 라고 물어본다.

### 2단계: 질문을 통한 기능 분석

아래 항목을 **한 번에 하나씩** 질문한다. 사용자 답변을 누적하며 진행한다.

1. 이 기능의 핵심 목적은 무엇인가? (한 줄로)
2. 주요 사용자는 누구인가?
3. 주요 사용 시나리오(해피 패스)를 단계별로 설명해 달라.
4. 예외 상황이나 엣지 케이스가 있는가?
5. 기존 화면이나 기능과 연관이 있는가?
6. 기술적 제약사항(API 연동, 성능 요건, 접근성 등)이 있는가?

### 3단계: 산출물 저장

`docs/design/$ARGUMENTS/` 디렉토리를 만들고 아래 파일을 저장한다.

**`docs/design/$ARGUMENTS/brainstorm.md`:**
```markdown
# {feature} 브레인스토밍

## 목적
{목적}

## 사용자
{사용자}

## 사용 시나리오
{번호 목록}

## 엣지 케이스
{엣지 케이스 또는 "없음"}

## 연관 기능
{연관 기능 또는 "없음"}

## 기술적 제약
{제약사항 또는 "없음"}
```

**`docs/design/$ARGUMENTS/state.json`:**
```json
{
  "feature": "$ARGUMENTS",
  "current_step": "spec",
  "completed": ["brainstorm"],
  "artifacts": {
    "brainstorm": "docs/design/$ARGUMENTS/brainstorm.md"
  }
}
```

### 4단계: 완료 안내

```
✅ brainstorm 완료 → docs/design/$ARGUMENTS/brainstorm.md

다음 단계: spec
  /design-flow $ARGUMENTS   (전체 플로우 계속)
  /spec $ARGUMENTS           (spec 단계만 실행)
```
````

- [ ] **Step 2: 파일 확인**

```bash
cat skills/brainstorm/SKILL.md | head -5
```

Expected: `---` 로 시작하는 frontmatter 출력

- [ ] **Step 3: 커밋**

```bash
git add skills/brainstorm/SKILL.md
git commit -m "feat: /brainstorm 스킬 추가 — 기능 분석 및 브레인스토밍"
```

---

### Task 3: spec 스킬 작성

`brainstorm.md`를 읽어 기능 목록, 화면 목록, API 인터페이스를 포함한 구조화된 스펙을 작성한다.

**Files:**
- Create: `skills/spec/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/spec/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
---
description: |
  브레인스토밍 결과를 바탕으로 기능 스펙 문서 작성.
  트리거: /spec {feature-name}
allowed-tools: Read, Write, Glob
agent: Sonnet
---

# Spec - 기능 스펙 작성

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 입력 파일 로드

`docs/design/$ARGUMENTS/brainstorm.md` 를 읽는다.
파일이 없으면: "brainstorm 단계를 먼저 완료해 주세요. `/brainstorm $ARGUMENTS`" 안내 후 종료.

### 2단계: 스펙 작성

brainstorm.md 내용을 바탕으로 스펙을 작성한다.
불명확한 항목이 있으면 사용자에게 추가 질문한다 (한 번에 하나씩).

**`docs/design/$ARGUMENTS/spec.md`:**
```markdown
# {feature} 스펙

## 기능 목록
- [ ] {기능1}
- [ ] {기능2}

## 화면 목록
| 화면명 | 경로 | 설명 |
|--------|------|------|
| {화면명} | /{경로} | {설명} |

## 컴포넌트 목록 (예상)
- {ComponentName}: {역할}

## API 인터페이스
| 메서드 | 경로 | 설명 |
|--------|------|------|
| {GET/POST} | /api/{경로} | {설명} |

없으면 "없음"으로 표기.

## 비기능 요건
- {접근성, 성능 요건 등. 없으면 "없음"}
```

### 3단계: state.json 업데이트

기존 state.json을 읽어 아래 항목을 업데이트한다:
- `completed` 배열에 `"spec"` 추가
- `current_step` → `"design-decision"`
- `artifacts.spec` → `"docs/design/$ARGUMENTS/spec.md"`

### 4단계: 완료 안내

```
✅ spec 완료 → docs/design/$ARGUMENTS/spec.md

다음 단계: design-decision
  /design-flow $ARGUMENTS       (전체 플로우 계속)
  /design-decision $ARGUMENTS   (design-decision 단계만 실행)
```
````

- [ ] **Step 2: 커밋**

```bash
git add skills/spec/SKILL.md
git commit -m "feat: /spec 스킬 추가 — 기능 스펙 문서 작성"
```

---

### Task 4: design-decision 스킬 작성

컬러 팔레트, 타이포그래피, 간격 시스템을 선택지 제시 후 사용자 승인을 받아 `design.md`로 저장한다.

**Files:**
- Create: `skills/design-decision/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/design-decision/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
---
description: |
  화면 디자인 방향 결정. 컬러 팔레트, 타이포그래피, 간격, 톤&무드를 선택지 제시 후 확정.
  트리거: /design-decision {feature-name}
allowed-tools: Read, Write, Glob
agent: Sonnet
---

# Design Decision - 디자인 방향 결정

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 입력 파일 로드

`docs/design/$ARGUMENTS/spec.md` 를 읽는다.
없으면 "spec 단계를 먼저 완료해 주세요." 안내 후 종료.

### 2단계: 디자인 방향 결정 (항목별 순서대로)

각 항목마다 선택지를 제시하고 사용자 승인을 받은 뒤 다음으로 넘어간다.

#### 2-1. 톤 & 무드

spec.md 기반으로 어울리는 방향 3가지를 제안한다. 예:
- **A. 깔끔/전문적** — 흰 배경, 파란 계열 Primary, 작은 border-radius
- **B. 따뜻/친근** — 크림 배경, 오렌지/앰버 계열, 큰 border-radius
- **C. 모던 다크** — 다크 그레이 배경, 네온 포인트색, 중간 border-radius

#### 2-2. 컬러 팔레트

선택된 톤 기준으로 구체적인 hex 값을 제안한다:

| 토큰명 | 값 | 용도 |
|--------|-----|------|
| primary | #{hex} | 주요 액션, 버튼 |
| secondary | #{hex} | 보조 강조색 |
| background | #{hex} | 페이지 배경 |
| surface | #{hex} | 카드, 패널 배경 |
| text-primary | #{hex} | 본문 텍스트 |
| text-secondary | #{hex} | 보조/힌트 텍스트 |
| error | #{hex} | 에러 상태 |

사용자가 값 수정을 요청하면 반영한다.

#### 2-3. 타이포그래피

| 항목 | 값 |
|------|-----|
| Font Family | {Google Fonts 기준} |
| Heading 1 | {크기}px / {굵기} |
| Heading 2 | {크기}px / {굵기} |
| Body | {크기}px / {굵기} |
| Caption | {크기}px / {굵기} |

#### 2-4. 간격 & 반경

| 항목 | 값 |
|------|-----|
| Base unit | {4 or 8}px |
| Border radius sm | {값}px |
| Border radius md | {값}px |
| Border radius lg | {값}px |
| Shadow | {CSS shadow 값} |

### 3단계: 산출물 저장

**`docs/design/$ARGUMENTS/design.md`:**
```markdown
# {feature} 디자인 결정

## 톤 & 무드
{선택한 방향 설명}

## 컬러 팔레트
| 토큰명 | 값 | 용도 |
|--------|-----|------|
| primary | #{hex} | 주요 액션, 버튼 |
| secondary | #{hex} | 보조 강조색 |
| background | #{hex} | 페이지 배경 |
| surface | #{hex} | 카드, 패널 배경 |
| text-primary | #{hex} | 본문 텍스트 |
| text-secondary | #{hex} | 보조/힌트 텍스트 |
| error | #{hex} | 에러 상태 |

## 타이포그래피
- Font: {폰트명}
- Heading 1: {크기}px / {굵기}
- Heading 2: {크기}px / {굵기}
- Body: {크기}px / {굵기}
- Caption: {크기}px / {굵기}

## 간격 시스템
- Base unit: {4 or 8}px
- Border radius: sm={}, md={}, lg={}px
- Shadow: {값}
```

state.json 업데이트:
- `completed` 에 `"design-decision"` 추가
- `current_step` → `"mockup"`
- `artifacts.design-decision` → `"docs/design/$ARGUMENTS/design.md"`

### 4단계: 완료 안내

```
✅ design-decision 완료 → docs/design/$ARGUMENTS/design.md

다음 단계: mockup
  /design-flow $ARGUMENTS   (전체 플로우 계속)
  /mockup $ARGUMENTS         (mockup 단계만 실행)
```
````

- [ ] **Step 2: 커밋**

```bash
git add skills/design-decision/SKILL.md
git commit -m "feat: /design-decision 스킬 추가 — 컬러/타이포/간격 결정"
```

---

### Task 5: mockup 스킬 작성

`spec.md` + `design.md`를 기반으로 화면별 HTML/CSS 인터랙티브 목업을 생성한다. Tailwind CDN + CSS Custom Properties 사용.

**Files:**
- Create: `skills/mockup/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/mockup/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
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

파일이 없으면 해당 단계 먼저 완료하도록 안내하고 종료.

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

- `completed` 에 `"mockup"` 추가
- `current_step` → `"component"`
- `artifacts.mockup` → `"docs/design/$ARGUMENTS/mockup/"`

```
✅ mockup 완료 → docs/design/$ARGUMENTS/mockup/

다음 단계: component
  /design-flow $ARGUMENTS   (전체 플로우 계속)
  /component $ARGUMENTS      (component 단계만 실행)
```
````

- [ ] **Step 2: 커밋**

```bash
git add skills/mockup/SKILL.md
git commit -m "feat: /mockup 스킬 추가 — HTML/CSS 인터랙티브 목업 생성"
```

---

### Task 6: component 스킬 작성

승인된 HTML 목업을 Vue SFC 컴포넌트로 변환하고, props/emit 인터페이스를 설계한다.

**Files:**
- Create: `skills/component/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/component/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
---
description: |
  승인된 HTML 목업을 Vue SFC 컴포넌트로 변환. props/emit 인터페이스 설계 포함.
  트리거: /component {feature-name}
allowed-tools: Read, Write, Glob, Bash
agent: Sonnet
---

# Component - Vue 컴포넌트 생성

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 입력 파일 로드

아래 파일을 모두 읽는다:
- `docs/design/$ARGUMENTS/mockup/*.html` (전체)
- `docs/design/$ARGUMENTS/design.md`
- `docs/design/$ARGUMENTS/spec.md`

### 2단계: 컴포넌트 분리 분석

HTML 목업을 분석하여 재사용 가능한 컴포넌트 단위를 식별한다.

**분리 기준:**
- 2개 이상의 화면에 반복되는 UI 패턴 → 독립 컴포넌트
- 명확히 다른 역할을 가진 섹션 → 독립 컴포넌트
- 단 한 번만 쓰이고 재사용 가능성이 없으면 분리하지 않는다 (YAGNI)

### 3단계: components.md 작성

`docs/design/$ARGUMENTS/components.md`:
```markdown
# {feature} 컴포넌트 목록

## 컴포넌트 트리
{컴포넌트 계층 구조, 예:
- {PageComponent}.vue
  - {CardComponent}.vue
  - {FormComponent}.vue
}

## 컴포넌트 상세

### {ComponentName}.vue
- **역할:** {한 줄 설명}
- **위치:** `src/components/{ComponentName}.vue`
- **Props:**
  | 이름 | 타입 | 필수 | 기본값 | 설명 |
  |------|------|------|--------|------|
  | {prop} | {String/Number/Boolean/Object} | yes/no | {값 또는 -} | {설명} |
- **Emits:**
  | 이벤트 | 페이로드 타입 | 설명 |
  |--------|--------------|------|
  | {event} | {type} | {설명} |
  없으면 "없음"
```

### 4단계: Vue SFC 파일 생성

components.md 기준으로 각 컴포넌트를 `src/components/` 에 생성한다.

**각 .vue 파일 규칙:**
- Composition API + `<script setup lang="ts">` 사용
- 목업 HTML을 template에 그대로 이식 (Tailwind 클래스 유지)
- CSS Custom Properties는 `style scoped`에서 `var(--color-primary)` 형식으로 참조
- 직접 hex 값 금지 — 반드시 CSS 변수 또는 Tailwind 클래스 사용

```vue
<script setup lang="ts">
interface Props {
  // components.md Props 그대로
}
const props = defineProps<Props>()

// emits
const emit = defineEmits<{
  '{event}': [{페이로드 타입}]
}>()
</script>

<template>
  <!-- 목업 HTML 이식, Tailwind 클래스 유지 -->
</template>

<style scoped>
/* CSS Custom Properties 참조만 허용 */
/* 예: color: var(--color-text-primary); */
</style>
```

### 5단계: state.json 업데이트 및 완료 안내

- `completed` 에 `"component"` 추가
- `current_step` → `"tokens"`
- `artifacts.component` → `"docs/design/$ARGUMENTS/components.md"`

```
✅ component 완료

생성된 컴포넌트:
  {ComponentName} → src/components/{ComponentName}.vue

문서: docs/design/$ARGUMENTS/components.md

다음 단계: tokens
  /design-flow $ARGUMENTS   (전체 플로우 계속)
  /tokens $ARGUMENTS         (tokens 단계만 실행)
```
````

- [ ] **Step 2: 커밋**

```bash
git add skills/component/SKILL.md
git commit -m "feat: /component 스킬 추가 — HTML 목업을 Vue SFC로 변환"
```

---

### Task 7: tokens 스킬 작성

`design.md`의 컬러/타이포/간격을 `tokens/colors.ts` → `tokens/semantic.ts` → `tailwind.config.ts` 구조로 추출한다.

**Files:**
- Create: `skills/tokens/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/tokens/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
---
description: |
  디자인 결정을 CSS Custom Properties + Tailwind config 토큰으로 추출.
  트리거: /tokens {feature-name}
allowed-tools: Read, Write, Glob, Bash
agent: Sonnet
---

# Tokens - 디자인 토큰 추출

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 입력 파일 로드

- `docs/design/$ARGUMENTS/design.md` 읽기
- `docs/design/$ARGUMENTS/components.md` 읽기

### 2단계: 기존 토큰 파일 확인

`tokens/` 디렉토리가 존재하면 기존 `colors.ts`, `semantic.ts` 를 읽어 병합 대상 확인.  
없으면 새로 생성한다.

### 3단계: 토큰 파일 생성/업데이트

**`tokens/colors.ts`** — primitive 토큰 (원색 팔레트):
```typescript
// 새 컬러는 기존 컬러 아래에 추가. 기존 값 수정 금지.
export const colors = {
  // === {feature} ({날짜}) ===
  {tokenName}: '{hex}',  // 예: primary500: '#3B82F6'
  // design.md 컬러 팔레트 전체를 여기에 primitive 단위로 추가
} as const;
```

**`tokens/semantic.ts`** — semantic 토큰 (역할 기반):
```typescript
import { colors } from './colors';

export const semantic = {
  // === {feature} ({날짜}) ===
  colorPrimary: colors.{primaryKey},
  colorSecondary: colors.{secondaryKey},
  colorBackground: colors.{backgroundKey},
  colorSurface: colors.{surfaceKey},
  colorTextPrimary: colors.{textPrimaryKey},
  colorTextSecondary: colors.{textSecondaryKey},
  colorError: colors.{errorKey},
} as const;
```

**`tailwind.config.ts`** — Nuxt 프로젝트 루트의 파일을 업데이트:
- 이미 존재하면: `theme.extend.colors` 에 semantic 토큰 키 추가
- 없으면: 아래 구조로 신규 생성

```typescript
import type { Config } from 'tailwindcss'
import { semantic } from './tokens/semantic'

export default {
  content: ['./src/**/*.{vue,ts}', './pages/**/*.vue', './components/**/*.vue'],
  theme: {
    extend: {
      colors: {
        primary: semantic.colorPrimary,
        secondary: semantic.colorSecondary,
        background: semantic.colorBackground,
        surface: semantic.colorSurface,
        'text-primary': semantic.colorTextPrimary,
        'text-secondary': semantic.colorTextSecondary,
        error: semantic.colorError,
      },
      fontFamily: {
        // design.md 폰트 추가
        sans: ['{design.md font}', 'sans-serif'],
      },
      borderRadius: {
        sm: '{design.md radius-sm}px',
        md: '{design.md radius-md}px',
        lg: '{design.md radius-lg}px',
      },
    },
  },
} satisfies Config
```

### 4단계: state.json 최종 업데이트

```json
{
  "feature": "$ARGUMENTS",
  "current_step": "done",
  "completed": ["brainstorm", "spec", "design-decision", "mockup", "component", "tokens"],
  "artifacts": {
    "brainstorm": "docs/design/$ARGUMENTS/brainstorm.md",
    "spec": "docs/design/$ARGUMENTS/spec.md",
    "design-decision": "docs/design/$ARGUMENTS/design.md",
    "mockup": "docs/design/$ARGUMENTS/mockup/",
    "component": "docs/design/$ARGUMENTS/components.md",
    "tokens": "tokens/"
  }
}
```

### 5단계: 완료 안내

```
✅ 디자인 플로우 전체 완료!

생성된 토큰:
  tokens/colors.ts    — primitive 컬러 팔레트
  tokens/semantic.ts  — semantic 토큰
  tailwind.config.ts  — Tailwind extend 설정

Tailwind 클래스 사용법:
  bg-primary, text-text-primary, border-surface
  rounded-md, shadow

이제 프론트엔드 개발을 시작할 수 있습니다.
```
````

- [ ] **Step 2: 커밋**

```bash
git add skills/tokens/SKILL.md
git commit -m "feat: /tokens 스킬 추가 — 디자인 토큰 추출 및 Tailwind 주입"
```

---

### Task 8: design-flow 오케스트레이터 스킬 작성

`state.json`을 읽어 현재 단계를 파악하고 해당 스킬 로직을 직접 실행하는 오케스트레이터.

**Files:**
- Create: `skills/design-flow/SKILL.md`

- [ ] **Step 1: SKILL.md 작성**

`skills/design-flow/SKILL.md` 를 아래 내용으로 작성한다:

````markdown
---
description: |
  디자인 플로우 오케스트레이터. state.json 기반으로 현재 단계 파악 후 해당 스킬 실행.
  트리거: /design-flow {feature-name} [--step {step}]
allowed-tools: Read, Write, Glob, Bash
agent: Sonnet
---

# Design Flow - 오케스트레이터

인자: **$ARGUMENTS**

## 실행 순서

### 1단계: 인자 파싱

`$ARGUMENTS` 에서 feature 이름과 `--step` 플래그를 파싱한다.

- `--step`이 없으면: state.json 기반 자동 단계 결정
- `--step {step}` 이 있으면: 해당 단계 강제 실행 (state.json의 current_step 무시)

예:
- `/design-flow user-profile` → feature = "user-profile", step = auto
- `/design-flow user-profile --step spec` → feature = "user-profile", step = "spec"

### 2단계: 현재 단계 결정

`docs/design/{feature}/state.json` 을 읽는다.

- 파일이 없으면: `current_step = "brainstorm"`
- `current_step`이 `"done"` 이면:
  ```
  ✅ {feature}의 디자인 플로우가 이미 완료되었습니다.
  특정 단계를 다시 실행하려면:
    /design-flow {feature} --step {brainstorm|spec|design-decision|mockup|component|tokens}
  ```
  → 종료

단계 순서:
```
brainstorm → spec → design-decision → mockup → component → tokens → done
```

### 3단계: 해당 단계 스킬 로직 실행

결정된 단계에 해당하는 스킬 파일을 읽고 그 내용을 실행한다.

| 단계 | 읽을 파일 |
|------|-----------|
| brainstorm | `skills/brainstorm/SKILL.md` |
| spec | `skills/spec/SKILL.md` |
| design-decision | `skills/design-decision/SKILL.md` |
| mockup | `skills/mockup/SKILL.md` |
| component | `skills/component/SKILL.md` |
| tokens | `skills/tokens/SKILL.md` |

스킬 파일을 읽은 후, 해당 스킬의 실행 순서를 **feature 이름을 대입하여** 그대로 수행한다.
````

- [ ] **Step 2: 커밋**

```bash
git add skills/design-flow/SKILL.md
git commit -m "feat: /design-flow 오케스트레이터 스킬 추가 — state.json 기반 단계 자동 실행"
```

---

### Task 9: CLAUDE.md에 Vue/Nuxt 디자인 플로우 가이드 추가

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: CLAUDE.md 에 섹션 추가**

`CLAUDE.md` 파일 끝에 아래 내용을 추가한다:

```markdown

## 디자인 플로우 (Vue/Nuxt)

신규 화면/기능 개발 시 반드시 아래 순서를 따른다.

### 플로우 시작
```
/design-flow {feature-name}
```
최초 호출 시 brainstorm부터 시작. 중단 후 재호출 시 마지막 단계부터 이어받음.

### 단계별 개별 실행
| 단계 | 명령어 | 산출물 |
|------|--------|--------|
| 브레인스토밍 | `/brainstorm {feature}` | `docs/design/{feature}/brainstorm.md` |
| 스펙 작성 | `/spec {feature}` | `docs/design/{feature}/spec.md` |
| 디자인 결정 | `/design-decision {feature}` | `docs/design/{feature}/design.md` |
| 목업 | `/mockup {feature}` | `docs/design/{feature}/mockup/*.html` |
| 컴포넌트 | `/component {feature}` | `src/components/*.vue` |
| 디자인 토큰 | `/tokens {feature}` | `tokens/*.ts`, `tailwind.config.ts` |

### 규칙
- 컴포넌트는 목업 승인 후에 작성한다
- 디자인 토큰은 `tokens/` 폴더에서 중앙 관리한다
- 색상 값은 직접 사용 금지 — 반드시 CSS 변수 또는 Tailwind 클래스 사용
- 각 단계 산출물은 `docs/design/{feature}/` 에 저장한다
```

- [ ] **Step 2: 커밋**

```bash
git add CLAUDE.md
git commit -m "docs: CLAUDE.md에 Vue/Nuxt 디자인 플로우 가이드 추가"
```

---

### Task 10: install.sh에 신규 스킬 등록 추가

**Files:**
- Modify: `install.sh`

- [ ] **Step 1: 스킬 설치 루프 수정**

`install.sh` 에서 아래 줄을 찾는다:

```bash
for skill in plan review commit; do
```

이를 아래로 교체한다:

```bash
for skill in plan review commit brainstorm spec design-decision mockup component tokens design-flow; do
```

- [ ] **Step 2: 완료 메시지 섹션 수정**

`install.sh` 끝의 echo 블록에서 기존 스킬 목록 뒤에 추가한다:

```bash
echo "  - /brainstorm     : 기능 분석 및 브레인스토밍"
echo "  - /spec           : 기능 스펙 문서 작성"
echo "  - /design-decision: 컬러/타이포/간격 결정"
echo "  - /mockup         : HTML/CSS 인터랙티브 목업"
echo "  - /component      : Vue 컴포넌트 생성"
echo "  - /tokens         : 디자인 토큰 추출"
echo "  - /design-flow    : 전체 디자인 플로우 오케스트레이터"
```

- [ ] **Step 3: 동작 확인**

```bash
bash install.sh --dry-run 2>/dev/null || bash install.sh
```

설치 완료 메시지에 7개 신규 스킬이 포함됨을 확인한다.

- [ ] **Step 4: 커밋**

```bash
git add install.sh
git commit -m "chore: install.sh에 디자인 플로우 7개 스킬 등록 추가"
```

---

## 자체 검토

### 스펙 커버리지

| 스펙 요구사항 | 구현 Task |
|---|---|
| brainstorm 스킬 | Task 2 |
| spec 스킬 | Task 3 |
| design-decision 스킬 | Task 4 |
| mockup 스킬 (HTML/CSS, 브라우저) | Task 5 |
| component 스킬 (Vue SFC) | Task 6 |
| tokens 스킬 (CSS Var + Tailwind) | Task 7 |
| design-flow 오케스트레이터 | Task 8 |
| state.json 기반 재진입 | Task 8 (design-flow) |
| `--step` 플래그 강제 재실행 | Task 8 (design-flow) |
| CLAUDE.md 가이드 추가 | Task 9 |
| install.sh 스킬 등록 | Task 10 |

모든 스펙 요구사항이 커버됨. 누락 없음.

### 타입/인터페이스 일관성

- `state.json` 의 `current_step` 값: `brainstorm | spec | design-decision | mockup | component | tokens | done` — 모든 스킬에서 동일하게 사용
- `artifacts` 키: 각 스킬의 완료 안내와 state.json 업데이트 내용이 일치
- `docs/design/{feature}/` 경로: 모든 스킬에서 동일 패턴 사용
