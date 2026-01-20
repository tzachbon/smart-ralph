# Tasks: User Authentication

**Input**: Design documents from `/specs/001-user-auth/`
**Prerequisites**: plan.md (required), spec.md (required for user stories)

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2)

---

## Phase 1: Make It Work (POC)

**Purpose**: Get core functionality working, skip tests initially

### Setup and Infrastructure

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

- [ ] T003A [VERIFY] Setup checkpoint
  - **Do**: Verify project setup is complete and builds
  - **Verify**: `npm run build && npm run lint`
  - **Done when**: Build and lint pass

### Database and Core Utils

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
  - **Files**: src/utils/jwt.ts
  - **Done when**: Can sign and verify tokens
  - **Verify**: Manual verification
  - **Commit**: "feat: add JWT utilities"

- [ ] T006A [VERIFY] Core infrastructure checkpoint
  - **Do**: Verify database and utilities are working
  - **Verify**: `npx prisma validate` and manual JWT test
  - **Done when**: Schema valid, JWT functions work

### User Story 1: Registration (US1)

- [ ] T007 [US1] Implement password hashing utility
  - **Do**: Create hash/compare functions with bcrypt cost 12
  - **Files**: src/utils/password.ts
  - **Done when**: Can hash and compare passwords
  - **Verify**: Manual verification
  - **Commit**: "feat: add password hashing utility"
- [ ] T008 [US1] Create registration endpoint
  - **Do**: POST /api/auth/register with email/password validation
  - **Files**: src/routes/auth.ts, src/controllers/authController.ts
  - **Done when**: Endpoint accepts requests and creates users
  - **Verify**: `curl -X POST localhost:3000/api/auth/register -d '{"email":"test@example.com","password":"Test123!"}' -H 'Content-Type: application/json'`
  - **Commit**: "feat: implement user registration"

- [ ] T008A [VERIFY] Registration checkpoint
  - **Do**: Verify registration flow works end-to-end
  - **Verify**: Register new user, verify user exists in database
  - **Done when**: User can register and is stored correctly

### User Story 2: Login (US2)

- [ ] T009 [US2] Create login endpoint
  - **Do**: POST /api/auth/login, verify password, return JWT
  - **Files**: src/routes/auth.ts, src/controllers/authController.ts
  - **Done when**: Endpoint returns JWT on valid credentials
  - **Verify**: Register user, then login with same credentials
  - **Commit**: "feat: implement user login"

### User Story 3: Token Refresh (US3)

- [ ] T010 [US3] Create refresh token storage
  - **Do**: Implement RefreshToken model operations
  - **Files**: src/services/tokenService.ts
  - **Done when**: Can store/retrieve/invalidate refresh tokens
  - **Verify**: Manual verification
  - **Commit**: "feat: add refresh token service"
- [ ] T011 [US3] Create token refresh endpoint
  - **Do**: POST /api/auth/refresh validates token and issues new one
  - **Files**: src/routes/auth.ts, src/controllers/authController.ts
  - **Done when**: Refresh endpoint works
  - **Verify**: Manual test with curl
  - **Commit**: "feat: implement token refresh"

- [ ] T012 [VERIFY] POC checkpoint - All endpoints working
  - **Do**: Verify all auth flows work end-to-end
  - **Verify**: Register, login, refresh token sequence works
  - **Done when**: All endpoints return expected responses

**Checkpoint**: Phase 1 complete - POC validated

---

## Phase 2: Refactoring

**Purpose**: Clean up code, improve structure

- [ ] T013 [P] Extract validation schemas to separate module
  - **Do**: Move Zod schemas to src/schemas/auth.ts
  - **Files**: src/schemas/auth.ts, src/controllers/authController.ts
  - **Done when**: Schemas reusable across endpoints
  - **Verify**: All endpoints still work
  - **Commit**: "refactor: extract validation schemas"
- [ ] T014 [P] Improve error messages and codes
  - **Do**: Standardize error responses with specific codes
  - **Files**: src/middleware/errorHandler.ts, src/errors/
  - **Done when**: Errors have consistent format
  - **Verify**: Test error scenarios return proper codes
  - **Commit**: "refactor: standardize error handling"
- [ ] T015 Add request logging middleware
  - **Do**: Log incoming requests with timing info
  - **Files**: src/middleware/logger.ts
  - **Done when**: Requests logged to console
  - **Verify**: Make requests, check logs
  - **Commit**: "feat: add request logging"

- [ ] T016 [VERIFY] Refactoring checkpoint
  - **Do**: Verify code quality and all endpoints still work
  - **Verify**: Manual smoke test of all endpoints
  - **Done when**: No regressions

**Checkpoint**: Phase 2 complete - Code cleaned up

---

## Phase 3: Testing

**Purpose**: Add comprehensive test coverage

- [ ] T017 [P] Write JWT utility tests
  - **Do**: Test sign/verify functions
  - **Files**: src/utils/jwt.test.ts
  - **Done when**: Tests pass
  - **Verify**: `npm test -- jwt`
  - **Commit**: "test: add JWT utility tests"
- [ ] T018 [P] Write password utility tests
  - **Do**: Test hash/compare functions
  - **Files**: src/utils/password.test.ts
  - **Done when**: Tests pass
  - **Verify**: `npm test -- password`
  - **Commit**: "test: add password utility tests"

- [ ] T018A [VERIFY] Unit tests checkpoint
  - **Do**: Verify utility tests pass before integration tests
  - **Verify**: `npm test -- --testPathPattern="utils"`
  - **Done when**: All utility tests pass

- [ ] T019 [US1] Write registration API tests
  - **Do**: Test valid registration, duplicate email, weak password cases
  - **Files**: tests/integration/register.test.ts
  - **Done when**: All test cases pass
  - **Verify**: `npm test -- register`
  - **Commit**: "test: add registration API tests"
- [ ] T020 [US2] Write login API tests
  - **Do**: Test valid login, wrong password, unknown email cases
  - **Files**: tests/integration/login.test.ts
  - **Done when**: All test cases pass
  - **Verify**: `npm test -- login`
  - **Commit**: "test: add login API tests"
- [ ] T021 [US3] Write token refresh tests
  - **Do**: Test valid refresh, expired token, invalid token cases
  - **Files**: tests/integration/refresh.test.ts
  - **Done when**: All test cases pass
  - **Verify**: `npm test -- refresh`
  - **Commit**: "test: add token refresh tests"

- [ ] T022 [VERIFY] Testing checkpoint
  - **Do**: Run full test suite
  - **Verify**: `npm test`
  - **Done when**: All tests pass with good coverage

**Checkpoint**: Phase 3 complete - Tests added

---

## Phase 4: Quality Gates

**Purpose**: Final validation and documentation

- [ ] T023 [P] Add API documentation
  - **Do**: Document all auth endpoints in OpenAPI format
  - **Files**: docs/api.yaml
  - **Done when**: OpenAPI spec valid
  - **Verify**: `npx @redocly/cli lint docs/api.yaml`
  - **Commit**: "docs: add OpenAPI spec for auth endpoints"
- [ ] T024 [VERIFY] Final quality gate
  - **Do**: Run full test suite, lint, and build
  - **Verify**: `npm test && npm run lint && npm run build`
  - **Done when**: All checks pass

**Checkpoint**: Phase 4 complete - Ready for PR

---

## Dependencies

- Phase 1 (Make It Work): No dependencies
- Phase 2 (Refactoring): Depends on Phase 1
- Phase 3 (Testing): Depends on Phase 2
- Phase 4 (Quality Gates): Depends on Phase 3

## Notes

- [P] tasks can run in parallel within the same phase
- [VERIFY] tasks delegate to qa-engineer agent
- Phase 1 skips tests to validate POC quickly
- Tests added in Phase 3 after implementation is stable
- Each checkpoint validates the phase independently
