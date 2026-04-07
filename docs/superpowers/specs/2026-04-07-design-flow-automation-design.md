# Design Flow Automation — 스펙 문서

**작성일:** 2026-04-07  
**상태:** 승인됨  
**대상 스택:** Vue / Nuxt

---

## 목표

기능 요청부터 프론트엔드 개발까지 이어지는 디자인 플로우를 하네스에 통합하여 자동화한다.  
각 단계를 독립적인 스킬로 분리하고, `/design-flow` 오케스트레이터로 전체 흐름을 관리한다.

---

## 전체 플로우

```
기능 요청
  │
  ▼
[brainstorm]  →  brainstorm.md
  │
  ▼
[spec]        →  spec.md
  │
  ▼
[design-decision]  →  design.md
  │
  ▼
[mockup]      →  mockup/*.html  (브라우저 확인)
  │
  ▼
[component]   →  components.md + src/*.vue
  │
  ▼
[tokens]      →  tokens/*.ts + tailwind.config.ts 업데이트
```

---

## 아키텍처

### 오케스트레이터 (`/design-flow`)

- `docs/design/{feature}/state.json` 을 읽어 현재 단계를 파악한다
- 해당 단계 스킬을 호출한다
- 단계 완료 시 state.json을 업데이트하고 다음 단계를 안내한다
- `--step {단계명}` 플래그로 특정 단계 강제 재실행 가능

**트리거:**
- `/design-flow {feature-name}` — 전체 오케스트레이션 (최초 또는 이어받기)
- `/design-flow {feature-name} --step {step}` — 특정 단계 재실행

### 개별 스킬

각 스킬은 오케스트레이터 없이 단독 호출도 가능하다.  
단독 호출 시 `docs/design/{feature}/` 에서 필요한 이전 단계 산출물을 자동으로 로드한다.

| 스킬 | 트리거 | 입력 | 산출물 |
|------|--------|------|--------|
| brainstorm | `/brainstorm {feature}` | 사용자 질답 | `brainstorm.md` |
| spec | `/spec {feature}` | `brainstorm.md` | `spec.md` |
| design-decision | `/design-decision {feature}` | `spec.md` | `design.md` |
| mockup | `/mockup {feature}` | `spec.md` + `design.md` | `mockup/*.html` |
| component | `/component {feature}` | `mockup/*.html` + `design.md` | `components.md` (하네스 docs) + `src/components/*.vue` (Nuxt 프로젝트) |
| tokens | `/tokens {feature}` | `design.md` + `components.md` | `tokens/*.ts` + `tailwind.config.ts` |

---

## 상태 관리

### state.json 구조

```json
{
  "feature": "user-profile-card",
  "current_step": "mockup",
  "completed": ["brainstorm", "spec", "design-decision"],
  "artifacts": {
    "brainstorm": "docs/design/user-profile-card/brainstorm.md",
    "spec": "docs/design/user-profile-card/spec.md",
    "design-decision": "docs/design/user-profile-card/design.md"
  }
}
```

### 단계 완료 처리

1. 산출물 파일 저장
2. `state.json` 업데이트 (completed 추가, current_step 진행, artifacts 경로 기록)
3. 사용자에게 완료 메시지 + 다음 단계 안내

### 재진입

- 세션이 끊겨도 `/design-flow {feature}` 재호출로 중간 단계부터 이어받기 가능
- `state.json` 없으면 1단계(brainstorm)부터 시작

---

## 폴더 구조

### 하네스 (study-harness)

```
skills/
  design-flow/SKILL.md       # 오케스트레이터
  brainstorm/SKILL.md
  spec/SKILL.md
  design-decision/SKILL.md
  mockup/SKILL.md
  component/SKILL.md
  tokens/SKILL.md
```

### 실제 프로젝트 산출물

```
{nuxt-project}/
└── docs/
    └── design/
        └── {feature-name}/
            ├── state.json
            ├── brainstorm.md
            ├── spec.md
            ├── design.md
            ├── mockup/
            │   ├── main.html
            │   └── detail.html
            └── components.md
```

---

## 디자인 토큰 전략

**CSS Custom Properties → Tailwind config extend** 패턴을 사용한다.

```
tokens/
  colors.ts       # primitive 토큰 (원색 팔레트)
  semantic.ts     # semantic 토큰 (primary, surface, error 등)
  tailwind.config.ts  # 위 토큰을 theme.extend로 주입
```

목업 단계에서 Tailwind 클래스로 생성 → 컴포넌트 단계에서 그대로 이식.  
런타임 테마 전환이 필요한 경우 CSS Custom Properties로 처리.

---

## CLAUDE.md 추가 내용

```md
## 디자인 플로우 (Vue/Nuxt)
- 신규 화면은 반드시 /design-flow로 시작한다
- 디자인 토큰은 tokens/ 폴더에서 중앙 관리한다
- 컴포넌트는 목업 승인 후 작성한다
- 각 단계 산출물은 docs/design/{feature}/ 에 저장한다
```

---

## 성공 기준

- `/design-flow {feature}` 한 번으로 brainstorm부터 tokens까지 순서대로 진행된다
- 세션 중단 후 재호출 시 중간 단계부터 자연스럽게 이어받는다
- 각 단계 스킬은 단독으로도 정상 동작한다
- 목업(HTML) → Vue 컴포넌트 변환 시 디자인 토큰이 일관되게 적용된다
