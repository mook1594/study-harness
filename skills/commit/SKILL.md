---
description: |
  변경사항을 분석하여 커밋 메시지를 작성하고 feature 브랜치에 커밋.
  main 브랜치이면 자동으로 feature 브랜치 생성.
  트리거: /commit, "커밋해줘", "커밋"
allowed-tools: Bash, Read
agent: Haiku
---

# Commit - 커밋 메시지 작성 및 커밋

$ARGUMENTS

아래 순서로 실행하세요.

## 1단계: 현재 상태 확인

```bash
git status
git diff --staged
git diff
```

staged 변경이 없으면 `git add -A` 실행 여부를 물어보세요.

## 2단계: 브랜치 확인

```bash
git branch --show-current
```

main 또는 master이면:
```bash
git checkout -b feature/YYYYMMDD-간단한기능명
```
브랜치명은 변경 내용에 맞게 작성하세요.

## 3단계: 커밋 메시지 작성

변경사항을 분석하여 커밋 메시지를 작성합니다.

형식:
```
<type>: <한 줄 요약>

<선택: 필요한 경우 상세 설명>
```

type 선택:
- `feat`: 새 기능
- `fix`: 버그 수정
- `test`: 테스트 추가/수정
- `refactor`: 리팩토링
- `chore`: 설정, 빌드 변경

## 4단계: 커밋 실행

작성한 메시지로 커밋:
```bash
git add -A
git commit -m "<메시지>"
```

커밋 후 어떤 브랜치에 커밋되었는지 알려주세요.
