---
type: index-summary
generated: true
indexed: {{TIMESTAMP}}
---

# Codebase Index

## Overview

| Category | Count | Last Updated |
|----------|-------|--------------|
{{#each CATEGORIES}}
| {{name}} | {{count}} | {{lastUpdated}} |
{{/each}}
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
{{#each EXTERNAL}}
| [{{name}}](external/{{file}}) | {{type}} | {{fetched}} |
{{/each}}

## Index Settings

- **Excluded patterns**: {{EXCLUDES}}
- **Indexed paths**: {{PATHS}}
