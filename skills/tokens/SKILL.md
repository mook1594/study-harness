---
description: |
  디자인 결정을 CSS Custom Properties + Tailwind config 토큰으로 추출.
  트리거: /tokens {feature-name}
allowed-tools: Read, Write, Glob, Bash
agent: Sonnet
---

# Tokens - 디자인 토큰 추출

기능명: **$ARGUMENTS**

## 실행 순서

### 1단계: 입력 파일 로드

- `docs/design/$ARGUMENTS/design.md` 읽기
- `docs/design/$ARGUMENTS/components.md` 읽기

파일이 없으면:
- `design.md` 없음 → "design-decision 단계를 먼저 완료해 주세요. `/design-decision $ARGUMENTS`" 안내 후 종료
- `components.md` 없음 → "component 단계를 먼저 완료해 주세요. `/component $ARGUMENTS`" 안내 후 종료

### 2단계: 기존 토큰 파일 확인

`tokens/` 디렉토리가 존재하면 기존 `colors.ts`, `semantic.ts` 를 읽어 병합 대상 확인.
없으면 새로 생성한다.

### 3단계: 토큰 파일 생성/업데이트

**`tokens/colors.ts`** — primitive 토큰 (원색 팔레트):
```typescript
// 새 컬러는 기존 컬러 아래에 추가. 기존 값 수정 금지.
export const colors = {
  // === {feature} ({날짜}) ===
  {tokenName}: '{hex}',  // 예: primary500: '#3B82F6'
  // design.md 컬러 팔레트 전체를 여기에 primitive 단위로 추가
} as const;
```

**`tokens/semantic.ts`** — semantic 토큰 (역할 기반):
```typescript
import { colors } from './colors';

export const semantic = {
  // === {feature} ({날짜}) ===
  colorPrimary: colors.{primaryKey},
  colorSecondary: colors.{secondaryKey},
  colorBackground: colors.{backgroundKey},
  colorSurface: colors.{surfaceKey},
  colorTextPrimary: colors.{textPrimaryKey},
  colorTextSecondary: colors.{textSecondaryKey},
  colorError: colors.{errorKey},
} as const;
```

**`tailwind.config.ts`** — Nuxt 프로젝트 루트의 파일을 업데이트:
- 이미 존재하면: `theme.extend.colors` 에 semantic 토큰 키 추가
- 없으면: 아래 구조로 신규 생성

```typescript
import type { Config } from 'tailwindcss'
import { semantic } from './tokens/semantic'

export default {
  content: ['./src/**/*.{vue,ts}', './pages/**/*.vue', './components/**/*.vue'],
  theme: {
    extend: {
      colors: {
        primary: semantic.colorPrimary,
        secondary: semantic.colorSecondary,
        background: semantic.colorBackground,
        surface: semantic.colorSurface,
        'text-primary': semantic.colorTextPrimary,
        'text-secondary': semantic.colorTextSecondary,
        error: semantic.colorError,
      },
      fontFamily: {
        sans: ['{design.md 폰트명}', 'sans-serif'],
      },
      borderRadius: {
        sm: '{design.md radius-sm}px',
        md: '{design.md radius-md}px',
        lg: '{design.md radius-lg}px',
      },
    },
  },
} satisfies Config
```

### 4단계: state.json 업데이트

기존 `docs/design/$ARGUMENTS/state.json` 을 읽어 아래 항목만 업데이트한다:
- `completed` 배열에 `"tokens"` 추가 (기존 값 유지)
- `current_step` → `"done"`
- `artifacts.tokens` → `"tokens/"`

### 5단계: 완료 안내

```
✅ 디자인 플로우 전체 완료!

생성된 토큰:
  tokens/colors.ts    — primitive 컬러 팔레트
  tokens/semantic.ts  — semantic 토큰
  tailwind.config.ts  — Tailwind extend 설정

Tailwind 클래스 사용법:
  bg-primary, text-text-primary, border-surface
  rounded-md, shadow

이제 프론트엔드 개발을 시작할 수 있습니다.
```
