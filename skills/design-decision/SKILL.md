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
