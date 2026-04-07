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
- `--step {step}` 이 있으면: 해당 단계 강제 실행

예시:
- `user-profile` → feature = "user-profile", 자동 단계 결정
- `user-profile --step spec` → feature = "user-profile", step = "spec" 강제 실행

### 2단계: 현재 단계 결정

`docs/design/{feature}/state.json` 을 읽는다.

파일이 없으면: `current_step = "brainstorm"` 으로 시작.

`current_step`이 `"done"` 이고 `--step` 플래그도 없으면:
```
✅ {feature}의 디자인 플로우가 이미 완료되었습니다.

특정 단계를 다시 실행하려면:
  /design-flow {feature} --step brainstorm
  /design-flow {feature} --step spec
  /design-flow {feature} --step design-decision
  /design-flow {feature} --step mockup
  /design-flow {feature} --step component
  /design-flow {feature} --step tokens
```
→ 종료

단계 순서:
```
brainstorm → spec → design-decision → mockup → component → tokens → done
```

### 3단계: 해당 단계 스킬 로직 실행

결정된 단계에 해당하는 스킬 파일을 읽고, feature 이름을 대입하여 그 내용을 실행한다.

| 단계 | 읽을 파일 |
|------|-----------|
| brainstorm | `skills/brainstorm/SKILL.md` |
| spec | `skills/spec/SKILL.md` |
| design-decision | `skills/design-decision/SKILL.md` |
| mockup | `skills/mockup/SKILL.md` |
| component | `skills/component/SKILL.md` |
| tokens | `skills/tokens/SKILL.md` |

스킬 파일을 Read 도구로 읽은 뒤, 해당 스킬의 실행 순서를 **`$ARGUMENTS`의 feature 이름을 대입하여** 그대로 수행한다.
