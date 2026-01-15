---
description: Submit feedback or report an issue for Ralph Specum plugin.
arguments:
  - name: message
    description: Your feedback or issue description
    required: false
---

# Submit Feedback

Help improve Ralph Specum by submitting feedback or reporting issues.

## Instructions

1. **Check if `gh` CLI is available** by running: `which gh`

2. **If `gh` is available**, create an issue with the user's feedback:
   ```bash
   gh issue create --repo tzachbon/smart-ralph --title "<short title from feedback>" --body "<full feedback message>"
   ```
   - Extract a short, descriptive title from the feedback
   - Include the full feedback in the body
   - Add the label `feedback` if it exists

3. **If `gh` is NOT available**, inform the user:
   > The `gh` CLI is not installed or not authenticated. Please submit your feedback manually at:
   >
   > **https://github.com/tzachbon/smart-ralph/issues/new**
   >
   > Or browse existing issues: https://github.com/tzachbon/smart-ralph/issues?q=sort%3Aupdated-desc+is%3Aissue+is%3Aopen

4. **If no message was provided**, ask the user what feedback they'd like to submit.

## Example Usage

```
/ralph-specum:feedback The task verification system sometimes misses TASK_COMPLETE markers
/ralph-specum:feedback Feature request: add support for parallel task execution
/ralph-specum:feedback Bug: cancel command doesn't cleanup .ralph-state.json properly
```
