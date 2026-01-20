# Feature Specification: User Authentication

**Feature Branch**: `001-user-auth`
**Created**: 2026-01-20
**Status**: Draft
**Input**: User description: "Add JWT-based user authentication"

## User Scenarios & Testing

### User Story 1 - User Registration (Priority: P1)

Users can create an account with email and password.

**Why this priority**: Foundation for all authenticated features. No other auth features work without registration.

**Independent Test**: Can be fully tested by POSTing to /api/auth/register and verifying user created in database.

**Acceptance Scenarios**:

1. **Given** no existing user, **When** user submits valid email/password, **Then** account created and JWT returned
2. **Given** existing email, **When** user attempts registration, **Then** 409 Conflict with "email exists" message
3. **Given** weak password, **When** user submits registration, **Then** 400 Bad Request with validation errors

---

### User Story 2 - User Login (Priority: P1)

Registered users can login to receive a JWT token.

**Why this priority**: Required for accessing any protected resources. Pairs with registration.

**Independent Test**: Register user, then POST to /api/auth/login with credentials.

**Acceptance Scenarios**:

1. **Given** valid credentials, **When** user submits login, **Then** JWT token returned with 1h expiry
2. **Given** invalid password, **When** user attempts login, **Then** 401 Unauthorized
3. **Given** non-existent email, **When** user attempts login, **Then** 401 Unauthorized (no email enumeration)

---

### User Story 3 - Token Refresh (Priority: P2)

Users can refresh their JWT before it expires.

**Why this priority**: Improves UX by avoiding re-login, but not critical for MVP.

**Independent Test**: Login, wait, POST to /api/auth/refresh with token.

**Acceptance Scenarios**:

1. **Given** valid non-expired token, **When** user requests refresh, **Then** new token issued
2. **Given** expired token, **When** user requests refresh, **Then** 401 Unauthorized

---

### Edge Cases

- What happens when user submits empty email? 400 validation error
- What happens when JWT signing key rotates? Old tokens invalid, must re-login
- What if database unavailable? 503 Service Unavailable with retry hint

## Requirements

### Functional Requirements

- **FR-001**: System MUST allow users to register with email and password
- **FR-002**: System MUST hash passwords with bcrypt (cost factor 12)
- **FR-003**: System MUST issue JWT tokens with 1 hour expiry
- **FR-004**: System MUST validate email format (RFC 5322)
- **FR-005**: System MUST enforce password minimum 8 chars, 1 number, 1 special

### Key Entities

- **User**: id, email (unique), passwordHash, createdAt, updatedAt
- **RefreshToken**: id, userId, token, expiresAt, createdAt

## Success Criteria

### Measurable Outcomes

- **SC-001**: Registration completes in under 500ms p99
- **SC-002**: Login completes in under 200ms p99
- **SC-003**: 100% of passwords hashed (no plaintext)
- **SC-004**: JWT validation adds under 5ms to request latency
