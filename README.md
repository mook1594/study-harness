# Study Harness

C#/.NET TDD 개발을 위한 Claude Code 자동화 하네스.

## 포함 내용

| 구성요소 | 설명 |
|---|---|
| `CLAUDE.md` | TDD 가이드, 코드 컨벤션, 브랜치 전략 |
| `hooks/pre-tool-use/git_guard.py` | main 브랜치 직접 커밋 차단 |
| `hooks/post-tool-use/edit_lint_test.sh` | .cs 파일 저장 시 `dotnet build` + `dotnet test` 자동 실행 |
| `skills/plan/` | `/plan` — TDD 구현 계획 작성 |
| `skills/review/` | `/review` — 코드 리뷰 |
| `skills/commit/` | `/commit` — 커밋 메시지 생성 및 커밋 |

## 설치

### 사전 요구사항

- [Claude Code](https://claude.ai/download) 설치
- `jq` 설치: `brew install jq`

### 설치 방법

```bash
git clone https://github.com/yourname/study-harness
cd study-harness
./install.sh
```

Claude Code를 재시작하면 적용됩니다.

## 개발 플로우

```
/plan → 테스트 작성(Red) → 구현(Green) → 자동빌드/테스트 → /review → /commit
```

### 1. `/plan` — 구현 계획 작성

```
/plan 사용자 로그인 기능 구현
```

요구사항을 분석하여 TDD 테스트 시나리오와 구현 단계를 생성합니다.

### 2. 테스트 먼저 작성 (Red)

`/plan` 결과를 바탕으로 실패하는 테스트를 먼저 작성합니다.

```csharp
// 예시: LoginService_ValidCredentials_ReturnsToken
[Fact]
public void Login_ValidCredentials_ReturnsToken()
{
    // ...
}
```

### 3. 최소 구현 (Green)

테스트를 통과하는 최소한의 코드를 작성합니다.
`.cs` 파일 저장 시 `dotnet build` + `dotnet test`가 자동으로 실행됩니다.

### 4. `/review` — 코드 리뷰

```
/review
```

TDD 준수 여부, 코드 품질, C# 컨벤션을 체크합니다.

### 5. `/commit` — 커밋

```
/commit
```

변경사항을 분석하여 커밋 메시지를 생성하고 feature 브랜치에 커밋합니다.
main 브랜치에서 실행하면 자동으로 feature 브랜치를 생성합니다.

## 자동화 동작

### main 브랜치 보호

main 브랜치에서 `git commit`을 실행하면 자동 차단됩니다.

```
main 브랜치에 직접 커밋할 수 없습니다.
먼저 'git checkout -b feature/20260407-143022' 를 실행하고 커밋하세요.
```

### 저장 시 자동 빌드/테스트

`.cs` 파일을 수정하면 자동으로 실행됩니다:

1. `dotnet build` — 빌드 오류 즉시 확인
2. `dotnet test` — 테스트 통과 여부 확인

## 새 프로젝트 시작

```bash
# 솔루션 생성
dotnet new sln -n MyApp

# 프로젝트 생성
dotnet new classlib -n MyApp -o src/MyApp
dotnet new xunit -n MyApp.Tests -o tests/MyApp.Tests

# 솔루션에 추가
dotnet sln add src/MyApp
dotnet sln add tests/MyApp.Tests

# 테스트 프로젝트에서 메인 프로젝트 참조
dotnet add tests/MyApp.Tests reference src/MyApp
```
