# Tasks: User Authentication

**Input**: Design documents from `/specs/001-user-auth/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create project structure with src/, tests/, docs/ directories
- [ ] T002 Initialize Node.js project with TypeScript and required dependencies
  - **Do**: Run npm init, install typescript, express, zod, jsonwebtoken, bcrypt
  - **Files**: package.json, tsconfig.json
  - **Done when**: npm install succeeds, tsc compiles
  - **Verify**: `npm run build`
  - **Commit**: "chore: initialize project with TypeScript"
- [ ] T003 [P] Configure ESLint and Prettier
  - **Do**: Add eslint, prettier configs for TypeScript
  - **Files**: .eslintrc.js, .prettierrc
  - **Done when**: npm run lint passes
  - **Verify**: `npm run lint`
  - **Commit**: "chore: add linting configuration"

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure required before any user story

- [ ] T004 Setup database schema with Prisma
  - **Do**: Initialize Prisma, create User and RefreshToken models
  - **Files**: prisma/schema.prisma
  - **Done when**: prisma generate succeeds
  - **Verify**: `npx prisma validate`
  - **Commit**: "feat: add database schema for auth"
- [ ] T005 [P] Create base error handling middleware
  - **Do**: Implement error handler with structured responses
  - **Files**: src/middleware/errorHandler.ts
  - **Done when**: Errors return JSON with code, message, details
  - **Verify**: Manual test with curl
  - **Commit**: "feat: add error handling middleware"
- [ ] T006 [P] Setup JWT utilities
  - **Do**: Create sign/verify functions with Zod schema for payload
  - **Files**: src/utils/jwt.ts, src/utils/jwt.test.ts
  - **Done when**: Tests pass for sign/verify
  - **Verify**: `npm test -- jwt`
  - **Commit**: "feat: add JWT utilities"

**Checkpoint**: Foundation ready

---

## Phase 3: User Story 1 - Registration (Priority: P1)

**Goal**: Users can create accounts
**Independent Test**: POST /api/auth/register with valid data

### Tests for User Story 1

- [ ] T007 [P] [US1] Write registration API tests
  - **Do**: Test valid registration, duplicate email, weak password cases
  - **Files**: tests/integration/register.test.ts
  - **Done when**: Tests exist and FAIL (not implemented yet)
  - **Verify**: `npm test -- register` fails with "not implemented"
  - **Commit**: "test: add registration API tests"

### Implementation for User Story 1

- [ ] T008 [US1] Implement password hashing utility
  - **Do**: Create hash/compare functions with bcrypt cost 12
  - **Files**: src/utils/password.ts
  - **Done when**: Can hash and compare passwords
  - **Verify**: `npm test -- password`
  - **Commit**: "feat: add password hashing utility"
- [ ] T009 [US1] Create registration endpoint
  - **Do**: POST /api/auth/register with email/password validation
  - **Files**: src/routes/auth.ts, src/controllers/authController.ts
  - **Done when**: Registration tests pass
  - **Verify**: `npm test -- register`
  - **Commit**: "feat: implement user registration"
- [ ] T010 [US1] [VERIFY] Quality checkpoint - Registration complete
  - **Do**: Verify registration flow works end-to-end
  - **Verify**: `curl -X POST localhost:3000/api/auth/register -d '{"email":"test@example.com","password":"Test123!"}' -H 'Content-Type: application/json'`
  - **Done when**: Returns 201 with JWT token

**Checkpoint**: User Story 1 complete

---

## Phase 4: User Story 2 - Login (Priority: P1)

**Goal**: Users can login to get JWT
**Independent Test**: POST /api/auth/login with valid credentials

### Tests for User Story 2

- [ ] T011 [P] [US2] Write login API tests
  - **Do**: Test valid login, wrong password, unknown email cases
  - **Files**: tests/integration/login.test.ts
  - **Done when**: Tests exist and FAIL
  - **Verify**: `npm test -- login` fails
  - **Commit**: "test: add login API tests"

### Implementation for User Story 2

- [ ] T012 [US2] Create login endpoint
  - **Do**: POST /api/auth/login, verify password, return JWT
  - **Files**: src/routes/auth.ts, src/controllers/authController.ts
  - **Done when**: Login tests pass
  - **Verify**: `npm test -- login`
  - **Commit**: "feat: implement user login"
- [ ] T013 [US2] [VERIFY] Quality checkpoint - Login complete
  - **Do**: Verify login flow works end-to-end
  - **Verify**: Register user, then login with same credentials
  - **Done when**: Login returns valid JWT

**Checkpoint**: User Story 2 complete

---

## Phase 5: User Story 3 - Token Refresh (Priority: P2)

**Goal**: Users can refresh tokens
**Independent Test**: POST /api/auth/refresh with valid token

### Implementation for User Story 3

- [ ] T014 [US3] Create refresh token storage
  - **Do**: Implement RefreshToken model operations
  - **Files**: src/services/tokenService.ts
  - **Done when**: Can store/retrieve/invalidate refresh tokens
  - **Verify**: Unit tests pass
  - **Commit**: "feat: add refresh token service"
- [ ] T015 [US3] Create token refresh endpoint
  - **Do**: POST /api/auth/refresh validates token and issues new one
  - **Files**: src/routes/auth.ts, src/controllers/authController.ts
  - **Done when**: Refresh endpoint works
  - **Verify**: `npm test -- refresh`
  - **Commit**: "feat: implement token refresh"

**Checkpoint**: All user stories complete

---

## Phase 6: Polish

**Purpose**: Final cleanup and documentation

- [ ] T016 [P] Add API documentation
  - **Do**: Document all auth endpoints in OpenAPI format
  - **Files**: docs/api.yaml
  - **Done when**: OpenAPI spec valid
  - **Verify**: `npx @redocly/cli lint docs/api.yaml`
  - **Commit**: "docs: add OpenAPI spec for auth endpoints"
- [ ] T017 [VERIFY] Final quality gate
  - **Do**: Run full test suite and lint
  - **Verify**: `npm test && npm run lint && npm run build`
  - **Done when**: All checks pass

---

## Dependencies

- Phase 1 (Setup): No dependencies
- Phase 2 (Foundation): Depends on Phase 1
- Phase 3 (US1): Depends on Phase 2
- Phase 4 (US2): Depends on Phase 2 (can run parallel with Phase 3)
- Phase 5 (US3): Depends on Phase 2
- Phase 6 (Polish): Depends on all user stories

## Notes

- [P] tasks can run in parallel within the same phase
- [VERIFY] tasks delegate to qa-engineer agent
- Tests written before implementation per TDD
- Each checkpoint validates the user story independently
