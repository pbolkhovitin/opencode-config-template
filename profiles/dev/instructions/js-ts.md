# JavaScript / TypeScript Instructions

## Toolchain
- Runtime: Node.js (via nvm or system)
- Package: npm / yarn / pnpm / bun
- TypeScript: npx tsc
- Lint: eslint
- Format: prettier

## Commands
- Build: `npm run build` or `tsc`
- Test: `npm test` or `vitest` / `jest`
- Lint: `npm run lint` or `eslint .`
- Format: `npx prettier --write .`
- Type check: `npx tsc --noEmit`

## Conventions (TS)
- Strict mode: `strict: true` in tsconfig
- Use `type` imports: `import type { Foo } from './foo'`
- Prefer `const` over `let`, avoid `var`
- Async/await over raw promises
- Use `zod` or `io-ts` for runtime validation
- Functional patterns preferred over classes

## Vue / React / Svelte
- SFC: `.vue` for Vue, `.tsx` for React, `.svelte` for Svelte
- Composition API (Vue) / hooks (React)
- Props: define explicit interfaces

## Verify
```bash
node --version && npm --version && npx tsc --version
```
