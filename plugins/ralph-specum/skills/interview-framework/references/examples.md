# Interview Examples

Example interview questions, "Other" response handling, and context storage patterns.

## Adaptive Depth -- "Other" Response Examples

Follow-up questions must be context-specific, not generic. When a user provides an "Other" response:

1. **Acknowledge the specific response** -- Reference what the user actually typed
2. **Ask a probing question based on response content** -- Analyze keywords in their response
3. **Include context from prior answers** -- Reference earlier responses to create continuity

Do NOT use generic follow-ups like "Can you elaborate?" -- always tailor to their specific response.

### GraphQL Example

If user types "We need GraphQL support" for a technical approach question:

```yaml
AskUserQuestion:
  question: "You mentioned needing GraphQL support. Is this for the entire API layer, or specific endpoints only?"
  options:
    - "Full API layer - replace REST"
    - "Hybrid - GraphQL for new endpoints only"
    - "Specific queries for mobile clients"
    - "Other"
```

### Security Example

If user types "Security is critical" for success criteria:

```yaml
AskUserQuestion:
  question: "You emphasized security is critical. Given your earlier constraints, which security aspects matter most?"
  options:
    - "Authentication and authorization"
    - "Data encryption at rest and in transit"
    - "Audit logging and compliance"
    - "Other"
```

## Context Accumulator -- Storage Format

After each interview, update `.progress.md`:

1. Read existing .progress.md content
2. Append new section under "## Interview Responses"
3. Use descriptive keys that reflect what was actually discussed
4. Include the chosen approach

```text
### [Phase] Interview (from [phase].md)
- [Topic 1]: [response]
- [Topic 2]: [response]
- Chosen approach: [name] -- [brief description]
[Any follow-up responses from "Other" selections]
```
