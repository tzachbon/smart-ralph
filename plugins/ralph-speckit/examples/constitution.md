# TaskFlow API Constitution

## Core Principles

### I. API-First Design
Every feature starts as an API endpoint. APIs must be versioned, documented, and independently testable. No UI work begins until API contracts are finalized.

### II. Type Safety
TypeScript strict mode required. No `any` types except in generated code. All API responses typed with Zod schemas. Runtime validation at system boundaries.

### III. Test-First Development
TDD mandatory for all business logic:
- Write failing test first
- Implement minimum code to pass
- Refactor with tests green
- Integration tests for API endpoints
- Unit tests for utilities

### IV. Error Handling
Structured error responses with:
- Error code (machine readable)
- Message (human readable)
- Details (debugging context)

All errors logged with correlation IDs. Never expose internal errors to clients.

### V. Observability
Every endpoint instrumented with:
- Request/response logging
- Latency metrics
- Error rate tracking
- Distributed tracing headers

## Security Requirements

- Authentication via JWT tokens
- Authorization via RBAC
- Input sanitization on all endpoints
- Rate limiting on public endpoints
- Secrets never in code or logs

## Development Workflow

1. Create feature branch from main
2. Write spec with user stories
3. Define API contracts
4. Implement with TDD
5. PR requires one approval
6. CI must pass before merge

## Governance

Constitution supersedes all other practices. Amendments require:
1. Written proposal
2. Team discussion
3. PR with updated constitution
4. Migration plan for breaking changes

**Version**: 1.0.0 | **Ratified**: 2026-01-15 | **Last Amended**: 2026-01-15
