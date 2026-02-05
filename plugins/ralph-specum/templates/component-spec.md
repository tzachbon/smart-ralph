---
type: component-spec
generated: true
source: {{SOURCE_PATH}}
hash: {{CONTENT_HASH}}
category: {{CATEGORY}}
indexed: {{TIMESTAMP}}
---

# {{COMPONENT_NAME}}

## Purpose
{{AUTO_GENERATED_SUMMARY}}

## Location
`{{SOURCE_PATH}}`

## Public Interface

### Exports
{{#each EXPORTS}}
- `{{this}}`
{{/each}}

### Methods
| Method | Parameters | Description |
|--------|------------|-------------|
{{#each METHODS}}
| {{name}} | {{params}} | {{description}} |
{{/each}}

## Dependencies
{{#each DEPENDENCIES}}
- `{{this}}`
{{/each}}

## AI Context
**Keywords**: {{KEYWORDS}}
**Related files**: {{RELATED_FILES}}
