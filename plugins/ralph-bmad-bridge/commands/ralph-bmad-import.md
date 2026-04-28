---
name: ralph-bmad:import
description: Import BMAD planning artifacts into a smart-ralph spec
---

# /ralph-bmad:import

Import BMAD planning artifacts into a smart-ralph spec.

## Usage

```
/ralph-bmad:import <bmad-project-path> <spec-name>
```

## Arguments

- **bmad-project-path** (required): Path to the BMAD project directory containing `_bmad-output/`
- **spec-name** (required): Name for the output spec (lowercase alphanumeric with hyphens)

## Implementation

# Parse positional arguments from $ARGUMENTS
BMAD_PATH=$(echo "$ARGUMENTS" | cut -d' ' -f1)
SPEC_NAME=$(echo "$ARGUMENTS" | cut -d' ' -f2)

# Validate args ($1=bmad_path, $2=spec_name)
if [ -z "$BMAD_PATH" ] || [ -z "$SPEC_NAME" ]; then
  echo "Usage: /ralph-bmad:import <bmad-project-path> <spec-name>"
  exit 1
fi

# Execute import.sh with $BMAD_PATH and $SPEC_NAME ($1 $2 from $ARGUMENTS)
bash "${CLAUDE_PLUGIN_ROOT}/scripts/import.sh" "$BMAD_PATH" "$SPEC_NAME"
exit $?
