---
enabled: true
default_max_iterations: 5
auto_commit_spec: true
quick_mode_default: false
specs_dirs: ["./specs"]
---

# Ralph Specum Configuration

This file configures Ralph Specum behavior for this project.

## Settings

### enabled
Enable or disable the workflow.

### default_max_iterations
Default maximum retries per failed task before blocking.

### auto_commit_spec
Whether to automatically commit spec files after generation.

### quick_mode_default
Whether quick mode should be the default when no flag is provided.

### specs_dirs
Array of directories where specs can be stored.
