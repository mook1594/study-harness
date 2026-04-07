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
