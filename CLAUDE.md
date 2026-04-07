# 개발 가이드 (C#/.NET + TDD)

## 기술 스택
- Language: C# (.NET 8+)
- Test: xUnit
- Build: `dotnet build`
- Test: `dotnet test`

## TDD 개발 플로우

**무조건 이 순서를 지킨다:**

1. **Red** — 실패하는 테스트 먼저 작성
2. **Green** — 테스트를 통과하는 최소한의 코드 작성
3. **Refactor** — 중복 제거, 가독성 개선

테스트 없이 구현 코드를 먼저 작성하지 않는다.

## 프로젝트 구조
```
src/
  ProjectName/
    ProjectName.csproj
tests/
  ProjectName.Tests/
    ProjectName.Tests.csproj
```

## 코드 컨벤션
- 클래스/메서드: PascalCase
- 변수/파라미터: camelCase
- 인터페이스 prefix: `I` (예: `IUserRepository`)
- 테스트 메서드명: `메서드명_상황_기대결과` (예: `Add_TwoPositiveNumbers_ReturnsSum`)

## 브랜치 전략
- `main`: 배포 가능한 상태만 유지
- 모든 작업은 feature 브랜치에서 진행
- 브랜치명: `feature/YYYYMMDD-기능명`

## 커밋 전 체크리스트
- [ ] `dotnet build` 성공
- [ ] `dotnet test` 전체 통과
- [ ] main 브랜치에서 직접 커밋하지 않음

## 설계 원칙
- YAGNI: 지금 필요한 것만 만든다
- 테스트 커버리지 100%를 목표로 하지 않는다 (핵심 로직에 집중)
- 인터페이스 남발하지 않는다 (구체 구현이 1개면 인터페이스 불필요)
