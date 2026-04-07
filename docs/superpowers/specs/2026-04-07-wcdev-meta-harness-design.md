# wcdev — 메타 하네스 설계

- 작성일: 2026-04-07
- 상태: 설계 확정 (구현 계획 미작성)
- 진입점: `/wcdev`

## 목적

`/wcdev "<제품 아이디어>"` 한 줄로 시작해, 마스터 에이전트가 사용자와 짧은 대화로 요구사항을 굳히고, 그 뒤로는 phase 단위 수직 슬라이스를 자율 반복하여 모노레포(프론트 + 백엔드)를 굴리는 메타 하네스. 사람의 개입은 요구사항 대화 1회 + 계약 승인 1회 + phase 실패 시 호출로 한정한다.

## 확정 결정 요약

1. **메타 하네스** — 사람이 슬래시 커맨드를 하나씩 치는 도구가 아니라, 에이전트가 제품 개발 전 과정을 자율 실행한다.
2. **레이어드 아키텍처** — `core/` + `tracks/<plugin>/`. 코어는 트랙을 모르고, 트랙은 다른 트랙을 모른다.
3. **진입점** — `/wcdev`. 인자 없이 호출하면 첫 질문부터 시작. 재호출 시 `state.json`으로 마지막 phase부터 재개.
4. **오케스트레이션** — 마스터 에이전트가 Task tool로 트랙별 서브에이전트를 fan-out, join 시 통합검증.
5. **기획 단계** — `superpowers:brainstorming` 패턴 기반 대화형. 그 이후 자율.
6. **4종 계약 산출물** — `docs/product/prd.md`, `docs/domain/model.md`, `docs/architecture/monorepo.md`, `contracts/openapi.yaml`.
7. **백엔드 언어** — C#/.NET 유지. OpenAPI를 단일 진실 공급원으로 두고 NSwag(C# DTO/컨트롤러) ↔ openapi-typescript(TS 타입) 양방향 코드생성.
8. **phase 단위** — 수직 슬라이스(use case 1개 = phase 1개). Contract → 양 트랙 Red → Green → 통합검증. **phase는 원자적**(부분 머지 금지).

## 1. 시스템 개요 & 진입점

- **진입점**: `/wcdev "<제품 아이디어>"` — 인자 없이 호출하면 마스터가 첫 질문부터 시작
- **재개**: `/wcdev` 재호출 시 `.harness/state.json` 읽고 마지막 phase부터 이어받음
- **상태/로그**: `.harness/state.json`(현재 phase·단계), `.harness/phases.json`(phase 리스트), `.harness/runs/<timestamp>/`(phase별 실행 로그·산출물)

## 2. 레이어드 아키텍처

```
study-harness/
├── core/                          # 언어/도메인 무관
│   ├── CLAUDE.md
│   ├── hooks/
│   │   ├── pre-tool-use/git_guard.py
│   │   └── post-tool-use/phase_gate.sh
│   ├── skills/
│   │   ├── wcdev/                 # 진입점 = 마스터 에이전트
│   │   ├── commit/
│   │   └── phase-runner/          # 한 phase 실행 엔진
│   └── contracts/
│       └── track-plugin.md        # 트랙 플러그인 인터페이스 명세
│
├── tracks/
│   ├── backend-csharp-tdd/
│   │   ├── plugin.json
│   │   ├── CLAUDE.md.fragment
│   │   ├── hooks/post-tool-use/edit_lint_test.sh
│   │   └── skills/{plan,write-tests,implement,self-verify}/
│   │
│   └── frontend-vue-design/
│       ├── plugin.json
│       ├── CLAUDE.md.fragment
│       └── skills/
│           ├── brainstorm/  spec/  design-decision/
│           ├── mockup/  component/  tokens/
│           ├── write-tests/  implement/  self-verify/
│
└── install.sh
```

**핵심 규칙**
- 코어는 트랙을 모름 — `plugin.json` 인터페이스만 안다
- 트랙은 다른 트랙을 모름 — 통신은 마스터 + 계약 문서를 통해서만
- 새 트랙 추가 = `tracks/<name>/` 폴더 + `plugin.json`. 코어 코드 변경 없음

## 3. 마스터 에이전트 흐름

```
[0] 부트
    state.json 있음? → 마지막 phase 재개로 점프
    없음 → [1]

[1] 요구사항 대화 (사람 개입 1회)
    superpowers:brainstorming 패턴
    질문 한 번에 하나씩, 4~7개:
      한 줄 제품 정의 / 타겟 유저 / 핵심 use case 3~5개
      인증 / 데이터 영속성 / 외부 연동

[2] 계약 문서 4종 생성 (자율)
    docs/product/prd.md
    docs/domain/model.md
    docs/architecture/monorepo.md
    contracts/openapi.yaml

[3] phase 분해 (자율)
    PRD의 use case → .harness/phases.json
      phase 0: scaffold
      phase 1: <use case 1>
      ...

[4] 사람 승인 게이트 (사람 개입 1회)
    "계약 4종 + phase 리스트입니다. 진행하시겠어요?"

[5] phase 루프 (자율)
    for phase in phases.json:
      state.json 갱신
      core/skills/phase-runner 호출:
        5a. 마스터: 이 phase의 contract 슬라이스 추출
        5b. fan-out (Task tool, 두 서브에이전트 동시)
        5c. join: 두 트랙 결과 수집
        5d. 통합 검증 (5장)
        5e. 통과 → commit, 다음 phase
            실패 → 사람 호출

[6] 종료
    모든 phase 통과 → 최종 리포트
    main 머지는 사람이 결정
```

**중단/재개**: phase 단위가 원자성 단위. phase 5 중 끊겼다면 그 phase부터 재시작(중간 상태 폐기).

**사람 개입 총량**: 단 2회(요구사항 대화 + 계약 승인) + phase 실패 시 호출.

## 4. 서브에이전트 트랙 내부 흐름

두 트랙 모두 동일한 4단계 골격: **Plan/Design → Write Tests (Red) → Implement (Green) → Self-verify**.

### 공통 입력
- `contracts/openapi.yaml` 중 이 phase의 슬라이스
- `docs/domain/model.md` 관련 엔티티
- `docs/architecture/monorepo.md` (작업 디렉토리 경계)
- 이 phase의 use case 설명
- `phase_id`, `runs/<ts>/<phase>/`

### 공통 출력 (`runs/<ts>/<phase>/<track>.json`)

```json
{
  "track": "backend-csharp-tdd",
  "status": "green | red | blocked",
  "tests": { "added": 7, "passing": 7, "failing": 0 },
  "files_changed": ["apps/api/..."],
  "build": "ok",
  "notes": "..."
}
```

### 4-A. backend-csharp-tdd

작업 디렉토리: `apps/api/**` 만.

```
[1] plan         → TDD 시나리오 산출
[2] write-tests  → NSwag로 DTO/컨트롤러 골격 생성, xUnit 테스트 작성
                   dotnet test → 반드시 실패해야 함 (Red 검증)
[3] implement    → 최소 구현, hook이 dotnet build && dotnet test 자동 실행
                   green까지 반복, 한도 5회
[4] self-verify  → clean run + /review skill, status: green
```

### 4-B. frontend-vue-design

작업 디렉토리: `apps/web/**`, `packages/shared-types/**`(읽기 전용).

```
[1] design       → brainstorm → spec → design-decision → mockup
                   (기존 7단계 디자인 플로우를 phase 단위로 압축)
[2] write-tests  → openapi-typescript로 TS 타입/클라이언트 생성
                   Vitest + Vue Test Utils 시나리오 작성
                   pnpm test → 반드시 실패해야 함
[3] implement    → component + tokens, green까지 반복
[4] self-verify  → pnpm -w build && pnpm -w test
```

### 핵심 불변식

- 두 트랙은 OpenAPI 외에 서로의 코드/문서를 보지 않는다
- 두 트랙이 동시에 동일 파일을 건드릴 수 없다 (디렉토리 경계 + shared-types는 자동 생성물)
- 트랙 hook은 자기 트랙의 workdir_globs 안에서만 발동
- 한 트랙이 blocked면 phase 전체 실패 — 부분 성공 없음

## 5. 통합 검증 & phase 게이트

마스터가 두 트랙으로부터 `green`을 받은 직후 실행. 위에서 아래로, 실패 즉시 중단.

```
[a] 계약 정합성
    spectral lint
    NSwag 재생성 결과 ↔ apps/api 컨트롤러 시그니처 diff = 0
    openapi-typescript 재생성 결과 ↔ packages/shared-types diff = 0

[b] 양 트랙 클린 빌드
    dotnet build && pnpm -w build

[c] 양 트랙 클린 테스트
    dotnet test && pnpm -w test

[d] 통합 시나리오 (E2E 1개 = 이 phase의 use case)
    apps/api 백그라운드 기동 → Playwright → 정리

[e] phase 게이트 통과
    한 commit으로 묶어 feature 브랜치 커밋
    "phase N: <use case> — TDD green + integration ok"
    phases.json 완료 마킹, state.json 다음 phase로
```

### 실패 시 동작

- **[a] 계약 drift**: 원인 트랙만 재기동 (다른 트랙 결과 보존). 재시도 한도 2회 → 사람 호출
- **[b][c] 빌드/테스트**: 해당 트랙 재기동 1회 → 사람 호출
- **[d] E2E**: 자동 재시도 안 함 — 사람 호출 (의미 오류는 LLM 추가 시도가 비효율)

### phase 게이트 hook

`core/hooks/post-tool-use/phase_gate.sh`. 마스터가 phase 종료 마커(`.harness/runs/<ts>/<phase>/CLOSE`)를 쓸 때 발동 → [a]~[d] 강제 실행. 마스터가 검증을 건너뛰는 사고를 물리적으로 차단.

### 부분 성공 금지

phase는 원자적이다. 통째로 green이거나 통째로 다시 한다. 부분 머지를 허용하면 다음 phase의 기준선이 흔들려 자율 시스템의 재현 가능성이 무너진다.

## 6. 설치 · CLAUDE.md · 모노레포 부트스트랩

### 6-1. install.sh

```bash
./install.sh                                                # 코어만
./install.sh --tracks backend-csharp-tdd,frontend-vue-design
./install.sh --all
```

수행:
1. 코어 설치 (`~/.claude/CLAUDE.md`, `hooks/`, `skills/{wcdev,commit,phase-runner}`, `settings.json` hook 등록)
2. 트랙별 설치 (`plugin.json` 검증 → `skills/`, `hooks/` 복사 → `CLAUDE.md.fragment`를 마커 블록으로 append, 멱등)
3. `~/.claude/.wcdev/installed-tracks.json` 등록부 생성
4. 사전 점검 (`claude`, `jq`, 트랙별 binaries)

### 6-2. core/CLAUDE.md 구조

```markdown
# Claude Code Harness — wcdev

신규 작업은 `/wcdev` 로 시작.

## 공통 원칙
- TDD: Red → Green → Refactor
- main 직접 커밋 금지 (git_guard hook)
- 커밋 단위: phase 1개 = commit 1개
- phase 게이트 우회 금지

## 산출물 위치
- contracts/openapi.yaml, docs/{product,domain,architecture}/
- .harness/state.json, .harness/phases.json, .harness/runs/

## 활성 트랙
<!-- BEGIN TRACK: backend-csharp-tdd -->
<!-- END TRACK: backend-csharp-tdd -->
<!-- BEGIN TRACK: frontend-vue-design -->
<!-- END TRACK: frontend-vue-design -->
```

### 6-3. 모노레포 부트스트랩 (phase 0 = scaffold)

```
<project>/
├── apps/
│   ├── api/                    # backend 트랙 영역 (dotnet 8 webapi + xunit)
│   └── web/                    # frontend 트랙 영역 (nuxt)
├── packages/
│   └── shared-types/           # openapi-typescript 산출물 (직접 수정 금지)
├── contracts/openapi.yaml      # 단일 진실 공급원
├── docs/{product,domain,architecture}/
├── .harness/{state.json,phases.json,runs/}
├── pnpm-workspace.yaml
├── tools/
│   ├── gen-shared-types.sh     # openapi-typescript 호출
│   └── gen-csharp-dtos.sh      # NSwag 호출
└── README.md                   # PRD 요약 자동 생성
```

phase 0 게이트:
- `dotnet build` 성공 (빈 webapi)
- `pnpm -w build` 성공 (빈 nuxt)
- `tools/gen-shared-types.sh` → `packages/shared-types/src/api.ts` 생성
- `tools/gen-csharp-dtos.sh` → `apps/api/src/Api.Generated/` 생성

## 7. 트랙 플러그인 인터페이스 & 확장

### 7-1. 트랙 디렉토리 규약

```
tracks/<track-name>/
├── plugin.json          # 필수
├── CLAUDE.md.fragment   # 선택
├── hooks/               # 선택
└── skills/              # 필수 (최소 1개)
```

### 7-2. plugin.json 스키마

```json
{
  "name": "backend-csharp-tdd",
  "version": "0.1.0",
  "role": "backend",
  "workdir_globs": ["apps/api/**"],
  "readonly_globs": ["contracts/**", "packages/shared-types/**"],
  "requires": {
    "binaries": ["dotnet"],
    "node_min": null
  },
  "phase_skills": {
    "plan":         "plan",
    "write_tests":  "write-tests",
    "implement":    "implement",
    "self_verify":  "self-verify"
  },
  "inputs_from_master": [
    "contracts/openapi.yaml",
    "docs/domain/model.md",
    "docs/architecture/monorepo.md"
  ],
  "report_path": ".harness/runs/{phase}/{name}.json",
  "codegen": {
    "command": "tools/gen-csharp-dtos.sh",
    "outputs": ["apps/api/src/Api.Generated/**"]
  }
}
```

### 7-3. phase-runner ↔ 트랙 호출 규약

1. **격리**: Task tool로 서브에이전트 기동, 시스템 프롬프트에 트랙명·phase_id·workdir_globs·readonly_globs·inputs 포함. "경계 밖 파일을 수정하면 즉시 중단" 강제 규칙.
2. **순차 호출**: `plan` → `write_tests` → `implement` → `self_verify`.
3. **출력**: 서브에이전트는 `report_path`에 JSON 작성. 마스터는 그것만 읽음(자유 텍스트 무시).
4. **타임아웃**: phase별 기본 30분, plugin.json에서 override.

### 7-4. 새 트랙 추가 절차

1. `tracks/<name>/` 폴더 생성
2. `plugin.json` 작성 (role, workdir_globs, 4개 phase 스킬)
3. 4개 스킬 작성
4. (선택) `CLAUDE.md.fragment`
5. `./install.sh --tracks <name>` — **코어 코드 0줄 변경**

### 7-5. 트랙 간 충돌 방지

- `workdir_globs`가 다른 트랙과 교집합이면 install.sh가 거부
- `readonly_globs`는 교집합 허용 (계약 문서 공유는 정상)
- hook matcher는 자동으로 `workdir_globs`와 AND 결합

### 7-6. 향후 확장 시나리오 (참고용)

- `mobile-react-native` (frontend, `apps/mobile/**`)
- `infra-terraform` (infra)
- `docs-site` (docs, write-tests를 noop으로)
- `data-pipeline-python` (data)

모두 코어 변경 없이 디렉토리 추가만으로 가능.

## 비목표 (지금 만들지 않는 것)

- 백엔드 언어 선택 옵션 (C#/.NET 고정)
- 이벤트/큐 기반 멀티 에이전트 (현재는 마스터 + Task fan-out)
- `/wcdev --from-prd <file>` 같은 비대화형 입력 모드
- 자동 main 머지·자동 배포
- 트랙 버전 관리·의존성 해소 (지금은 단순 복사)

## 열린 질문 (구현 계획 단계에서 결정)

- `.harness/state.json` 정확한 스키마
- master 에이전트의 시스템 프롬프트 본문
- phase 분해 알고리즘 (PRD use case → phase 매핑 휴리스틱)
- 통합 검증 [d] E2E의 Playwright 시나리오 생성 방식 (마스터가 작성 vs 프론트 트랙이 작성)
- NSwag/openapi-typescript 도구 버전 핀
- 재시도 한도·타임아웃의 phase별 override 정책
