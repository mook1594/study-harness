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
