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
