# 개발 가이드 (C#/.NET + TDD | Vue/Nuxt 디자인 플로우)

## 기술 스택
- Language: C# (.NET 8+)
- Test: xUnit
- Build: `dotnet build`
- Test: `dotnet test`

### 프론트엔드 (디자인 플로우)
- Framework: Vue 3 / Nuxt
- Styling: Tailwind CSS + CSS Custom Properties
- 디자인 토큰: tokens/colors.ts → tokens/semantic.ts → tailwind.config.ts

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
