# Output Examples by Phase

## Research Phase

### Bad (verbose)
```
The authentication system will need to handle user login functionality.
In order to accomplish this, we will need to implement a JWT-based
authentication mechanism that allows users to securely log in.
```

### Good (concise)
```
Auth system: JWT-based login

Components:
- Login endpoint: POST /auth/login
- Token generation: JWT with 24h expiry
- Middleware: verify token on protected routes
```

## Requirements Phase

### Bad (verbose)
```
As a user, I would like to be able to log into the system so that I
can access my personal dashboard and view my data in a secure manner.
The system should validate my credentials against the database.
```

### Good (concise)
```
**US-1: User Login**
- Actor: Registered user
- Action: Authenticate via email/password
- Outcome: Access personal dashboard
- AC: Valid creds -> JWT token + redirect to /dashboard
- AC: Invalid creds -> 401 + error message
```

## Design Phase

### Bad (verbose)
```
The authentication module will be responsible for handling all aspects
of user authentication including login, logout, token refresh, and
session management. It will communicate with the database layer.
```

### Good (concise)
```
## Auth Module

| Component | Responsibility | Interface |
|-----------|---------------|-----------|
| LoginHandler | Validate credentials | POST /auth/login |
| TokenService | Issue/refresh JWT | generateToken(), refreshToken() |
| AuthMiddleware | Guard protected routes | verifyToken() |
```

## Tasks Phase

### Bad (verbose)
```
The first task will be to create the authentication module directory
structure and set up the necessary files. After that, we will need
to implement the login endpoint and write tests for it.
```

### Good (concise)
```
- [ ] 1.1 Create auth module at src/auth/
  - **Do**: mkdir src/auth, create index.ts, types.ts
  - **Verify**: `ls src/auth/`
  - **Commit**: `feat(auth): scaffold auth module`
```
