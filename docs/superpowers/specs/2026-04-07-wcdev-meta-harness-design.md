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

## 리뷰 결정 (2026-04-07)

원본 설계에 대한 리뷰 세션에서 정정·보강된 사항. 본문과 충돌 시 이 섹션이 우선한다.

### R1. `.harness/state.json` 스키마 확정

```json
{
  "schema_version": 1,
  "run_id": "2026-04-07T14-22-08",
  "product_idea": "...",
  "status": "running | awaiting_human | done",
  "phase": {
    "id": "phase-3",
    "index": 3,
    "use_case": "사용자가 할 일을 추가한다",
    "step": "contract-slice | fanout | join | verify-a | verify-b | verify-c | verify-d | verify-e | done",
    "attempts": { "backend": 1, "frontend": 0 }
  },
  "human_gates": {
    "requirements_done": true,
    "design_done": true,
    "contracts_approved": true
  },
  "bootstrap": { "scaffold_done": true },
  "contract_hashes": {
    "docs/product/prd.md": "sha256:...",
    "docs/domain/model.md": "sha256:...",
    "docs/architecture/monorepo.md": "sha256:...",
    "contracts/openapi.yaml": "sha256:..."
  },
  "escalation": {
    "reason": "verify-d E2E failed",
    "raised_at": "2026-04-07T15:01:33Z"
  },
  "last_updated": "..."
}
```

- `step`은 phase-runner 내부 단계까지 노출, `fanout`은 단일 step (트랙별 진행은 `attempts`)
- `status: done`은 전체 phase 완주만, phase 종료는 `step=done` + `index` 증가
- `attempts`는 트랙별 카운터

### R2. Escalation 메커니즘

- **전달**: `status: awaiting_human` + `escalation` 필드 + `.harness/runs/<ts>/<phase>/ESCALATION.md`(실패 단계, 트랙 report, 재현 명령, 추천 조치) 작성 후 **세션 종료** (state.json 잔존)
- **재개**: `/wcdev` 재호출 시 `awaiting_human`이면 `ESCALATION.md` 보여주고 1회 질문
  - 선택지: `retry | resume | discard | redecompose | abort`
  - `retry`: 실패 step부터, `attempts` 리셋
  - `resume`: 워킹트리 변경분 유지, 같은 phase 진입점부터
  - `discard`: `git stash push -u -m "wcdev-discard-<run_id>"` 후 phase 처음부터
  - `redecompose`: phase 리스트 재생성 (R8 참조)
  - `abort`: 종료
- **트리거**: §5 [a] 2회 초과 / §5 [b][c] 1회 초과 / §5 [d] 즉시 / 트랙 `blocked` / 타임아웃 / `track silent`(report 부재) / scaffold 실패 / 4종 파일 drift / 코어↔트랙 버전 drift / 워킹트리 dirty 진입
- **타임아웃**: 기본 30분, `phases.json` 항목별 override

### R3. 디자인 단계 분리 (구조 변경)

기존 §3·§4-B의 "phase마다 design/brainstorm/mockup 반복"을 폐기. 디자인은 **사전 1회성 단계**.

**새 마스터 흐름**
```
[1] 요구사항 대화 (사람)
[2] 계약 4종 생성 (자율)
[2.1] scaffold (자율, 전용 스킬) — phase 0 폐기, 별도 단계로 분리
[2.5] /design-flow 위임 (사람)
[3] phase 분해 (자율)
[4] 승인 게이트 (사람)
[5] phase 루프 (자율, phase 1~N)
[6] 종료
```

- 사람 개입 **3회**: 요구사항 / 디자인 / 계약+phase 승인
- 디자인 산출물: `docs/design/`, `tokens/` (전체), `packages/ui/` (핵심 primitive만 — Button/Input/Card 등)
- 디자인 단계 완료 판정: `/design-flow` 종료 + `tokens/`·`packages/ui/` 존재 확인
- §4-B 프론트 트랙 4단계로 축소: `plan → write-tests → implement → self-verify`
- `packages/ui/`, `tokens/`는 phase 트랙에서 **읽기 전용**
- phase 중 신규 컴포넌트는 `apps/web/` 내부 phase-local. `packages/ui` 승격은 사람 판단(비목표)
- (열린 질문) "프론트 design 단계 종료 조건"은 본 변경으로 해소

### R4. Scaffold 단계 (phase 0 대체)

- 전용 스킬 `core/skills/scaffold`
- 작업: 디렉토리 생성, `dotnet new webapi`, `nuxi init`, `pnpm-workspace.yaml`, `tools/gen-*.sh`, 빈 `/health` 엔드포인트, 빈 codegen 1회, Playwright chromium 설치
- 게이트: `dotnet build` ok, `pnpm -w build` ok, codegen 산출물 존재, `playwright --version` 확인
- 첫 commit: `chore: scaffold monorepo`
- state: `bootstrap.scaffold_done`
- 실패 시 일반 escalation 경로 동일 처리
- phase-runner는 "OpenAPI 슬라이스 있는 phase"만 담당 (phase 1부터)

### R5. Contract slice 추출

`phases.json` 항목:
```json
{
  "id": "phase-3",
  "use_case": "사용자가 할 일을 추가한다",
  "operations": ["createTodo", "listTodos"],
  "domain_entities": ["Todo"],
  "timeout_minutes": 30
}
```

- 추출 도구: 별도 스크립트 `tools/extract-slice.sh`
- 출력: `.harness/runs/<ts>/<phase>/contract-slice.yaml` (path item + 트랜지티브 schema 클로저)
- 트랙 서브에이전트는 슬라이스만 입력, **원본 `contracts/openapi.yaml` 접근 금지**
- §5 [a] 정합성 검증은 마스터가 원본 기준으로 수행

### R6. Codegen 실행 주체 (이중 실행, 의도된 동작)

| 시점 | 주체 | 입력 | 출력 |
|---|---|---|---|
| `write-tests` 진입 | 트랙 | `contract-slice.yaml` | `apps/api/src/Api.Generated/`, `packages/shared-types/src/api.ts` (commit) |
| §5 [a] 검증 | 마스터 | 원본 `openapi.yaml` | `.harness/runs/<ts>/<phase>/codegen-check/` (보존) |

- 산출물은 git **commit** (diff 검증을 위해)
- `pre-tool-use` hook으로 트랙 외부의 산출물 경로 쓰기 차단
- `.gitattributes`에 `linguist-generated` 표시
- §5 [a] diff = 0 강제, ≠ 0이면 escalation

### R7. 커밋 전략

- 트랙 hook은 build/test만, **git 명령 금지** (문서 + `pre-tool-use` hook 이중 차단)
- phase 시작 시 워킹트리 dirty면 escalation
- 트랙은 커밋 안 함, 워킹트리에 변경 누적
- §5 [a]~[d] 통과 후 마스터가 1회 커밋:
  - 명시적 add (트랙별 `workdir_globs` + codegen output 경로만)
  - `phase N: <use case> — TDD green + integration ok`
- 검증 실패 시 워킹트리 보존 + escalation

### R8. `git_guard` hook

- `core/hooks/pre-tool-use/git_guard.py`, `settings.json` 등록
- **책임 1: main 보호** — 현재 브랜치가 `main`이면 변경성 git 명령 거부, 읽기는 허용
- **책임 2: 트랙 git 차단** — phase-runner가 트랙 Task 호출 시 `WCDEV_TRACK=<name>` 주입, hook이 변수 있으면 모든 변경성 git 명령 거부
- **자동 브랜치 생성**: `/wcdev` 시작 시 `feature/wcdev-<run_id>` 자동 체크아웃
- **bypass 차단**: `--no-verify`, `core.hooksPath` 우회 시도 거부

### R9. 재개 시 미커밋 변경분 처리

- `git status --porcelain` 확인
- clean: 마지막 step부터 재개
- dirty: escalation 경로로 통합 (R2의 `retry | resume | discard | redecompose | abort`)
- `status: running` 상태로 재호출 발견 시 phase-runner가 자동으로 `awaiting_human` 전환 (`reason: unclean shutdown`)
- `status: done + dirty`: 메시지만 출력 후 종료, 자동 행동 없음
- discard 시 stash에 untracked 포함

### R10. Playwright 환경 부트스트랩 (§5 [d] 보강)

- **DB**: 요구사항 대화에서 결정 (디폴트 SQLite). `tools/db-provision.sh`/`db-teardown.sh` 추상화로 phase-runner는 DB 종류 모름. scaffold가 선택에 맞는 provisioner 설치. Postgres 선택 시 `install.sh` 사전 점검에 `docker` 추가. phase 1개 = 격리된 DB 인스턴스 1개. connection string은 환경변수로만 주입.
- **포트**: `ASPNETCORE_URLS=http://127.0.0.1:0` → OS 할당, stdout 파싱
- **health check**: scaffold가 `/health` 자동 추가, verify-d 진입 시 200까지 폴링(최대 30초)
- **종료 보장**: PID 파일 + bash trap, 다음 phase 진입 시 잔존 PID도 kill
- **E2E 작성 주체**: 마스터, `.harness/runs/<ts>/<phase>/e2e.spec.ts`
- **Playwright**: scaffold에서 chromium만 설치, cross-browser 비목표

### R11. 동시성/잠금

- **층 1**: 디렉토리 경계 (기존 `workdir_globs`)
- **층 2**: 루트 공유 파일 쓰기 금지 — `pnpm-lock.yaml`, 루트 `package.json`, `pnpm-workspace.yaml`, `.gitignore`, `README.md`, `.harness/**`, `contracts/**`, `tokens/**`, `packages/ui/**`
- **층 3**: 의존성 추가는 트랙이 직접 (`dotnet add package`, `pnpm add` in `apps/web/`). `pnpm-lock.yaml` 쓰기 권한은 프론트 트랙만. join 후 마스터가 lockfile 일관성 검사
- **층 4**: report 파일 경로 분리. state.json은 마스터 전용, 트랙은 읽기도 금지
- 신설 hook: `core/hooks/pre-tool-use/workdir_guard.py` — 트랙 컨텍스트에서 금지 경로 쓰기 거부

### R12. 작업 디렉토리 경계의 진실 공급원

- `plugin.json.workdir_globs`가 진실 공급원, `monorepo.md`는 파생 문서
- scaffold/install.sh가 `monorepo.md`의 마커 블록 자동 생성, 마커 외부는 사람 영역 (아키텍처 의도/결정)
- §5 [a]에 `monorepo.md` 마커 ↔ `plugin.json` drift 검사 추가

### R13. PRD/계약 변경 시 재phase 분해

- `state.json.contract_hashes`에 4종 파일 해시 기록 (scaffold/계약 생성 시점)
- 매 phase 진입 시 해시 비교, drift 발견 시 escalation
- 선택지: `redecompose | continue | abort`
- `redecompose`: use_case + operations 정확 매칭이면 `done` 유지, 부분 일치면 escalation으로 사람 결정
- `monorepo.md`는 마커 블록을 placeholder로 치환 후 해싱

### R14. 서브에이전트 컨텍스트 폭발

- 타임아웃 = blocked → escalation
- 트랙 시스템 프롬프트에 보고 의무 명시: 종료 전 `report_path` JSON 작성, 컨텍스트 부족 시 `status: blocked` 자진 보고
- 마스터 폴백 판정:
  - report 정상 → join
  - `status: blocked` → escalation (`track blocked`)
  - report 부재 → escalation (`track silent`, 워킹트리 변경분 첨부)
- 부분 산출물은 R9 경로로 처리

### R15. install.sh 멱등성/제거

- 멱등 install: 마커 블록만 교체, `installed-tracks.json` 버전 비교 후 같으면 no-op
- `--uninstall-track <name>`: `~/.claude/` 측 트랙 산출물·마커·등록 제거, 프로젝트 `tracks/<name>/`는 보존
- `--uninstall`: 코어 + 모든 트랙 제거, `~/.claude/.wcdev/` 삭제, `settings.json`은 wcdev hook만 제거, 프로젝트 `.harness/`는 보존
- 사전 점검: install 시 binaries 확인, uninstall 시 `status: running` 세션 있으면 거부 (force 없음)

### R16. Windows 지원

- macOS/Linux만 공식 지원, Windows는 WSL2 우회
- README 시스템 요구사항 명시
- install.sh가 비POSIX 셸 감지 시 경고만 출력 후 진행
- 비목표에 "Windows 네이티브 지원" 추가

### R17. 코어 ↔ 트랙 버전 호환성

- 코어 버전: `core/VERSION` (semver)
- 트랙: `plugin.json.requires.core`에 semver range
- install.sh: 트랙 설치 시 코어 호환 검증, 불만족 거부 (force 없음)
- 코어 업그레이드 시 모든 트랙 재검증, 비호환 트랙은 비활성화 표시 + 사용자 보고
- phase-runner 부트 시 `installed-tracks.json` ↔ 현재 코어 재검증, drift 시 escalation
- 코어 인터페이스 면적: `plugin.json` 스키마, phase-runner 호출 규약, hook 인터페이스
- 0.x 단계는 minor 증가도 breaking 가능

### R18. 사소한 정정

- §3 [5] 의사코드 "통합 검증 (5장)" → `§5` 표기 통일
- 재시도 명칭 분리: `green-loop budget` (트랙 내부 §4-A 5회) vs `phase retry budget` (§5 1~2회)
- §6-2 CLAUDE.md 트랙 마커 블록에 "install.sh가 채움" 주석 추가

---

## 열린 질문 (구현 계획 단계에서 결정)

- `.harness/state.json` 정확한 스키마
- master 에이전트의 시스템 프롬프트 본문
- phase 분해 알고리즘 (PRD use case → phase 매핑 휴리스틱)
- 통합 검증 [d] E2E의 Playwright 시나리오 생성 방식 (마스터가 작성 vs 프론트 트랙이 작성)
- NSwag/openapi-typescript 도구 버전 핀
- 재시도 한도·타임아웃의 phase별 override 정책
