---
type: index-summary
generated: true
indexed: {{TIMESTAMP}}
---

# Codebase Index

## Overview

| Category | Count | Last Updated |
|----------|-------|--------------|
<!-- markdownlint-disable MD055 MD056 -->
{{#each CATEGORIES}}
| {{name}} | {{count}} | {{lastUpdated}} |
{{/each}}
<!-- markdownlint-enable MD055 MD056 -->
| **Total** | **{{TOTAL}}** | {{TIMESTAMP}} |

## Components

### Controllers
{{#each CONTROLLERS}}
- [{{name}}](components/{{file}}) - {{purpose}}
{{/each}}

### Services
{{#each SERVICES}}
- [{{name}}](components/{{file}}) - {{purpose}}
{{/each}}

### Models
{{#each MODELS}}
- [{{name}}](components/{{file}}) - {{purpose}}
{{/each}}

### Helpers
{{#each HELPERS}}
- [{{name}}](components/{{file}}) - {{purpose}}
{{/each}}

### Migrations
{{#each MIGRATIONS}}
- [{{name}}](components/{{file}}) - {{purpose}}
{{/each}}

## External Resources

| Resource | Type | Fetched |
|----------|------|---------|
<!-- markdownlint-disable MD055 MD056 -->
{{#each EXTERNAL}}
| [{{name}}](external/{{file}}) | {{type}} | {{fetched}} |
{{/each}}
<!-- markdownlint-enable MD055 MD056 -->

## Index Settings

- **Excluded patterns**: {{EXCLUDES}}
- **Indexed paths**: {{PATHS}}
