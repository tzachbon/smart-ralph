import type { ParsedTask, ParallelGroup } from '../types/index.js';

// Matches: `- [ ] 1.8 [P] [VERIFY] Title text`
// Groups:  completed, id, tags, title
const TASK_LINE_RE = /^- \[([ x])\] (\S+)((?:\s+\[[^\]]+\])*)\s+(.*)/;

const BODY_FIELD_RE: Record<string, RegExp> = {
  do: /^\s{2,}\*\*Do\*\*:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n- \[|$)/,
  files: /^\s{2,}\*\*Files\*\*:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n- \[|$)/,
  doneWhen: /^\s{2,}\*\*Done when\*\*:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n- \[|$)/,
  verify: /^\s{2,}\*\*Verify\*\*:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n- \[|$)/,
  commit: /^\s{2,}\*\*Commit\*\*:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n- \[|$)/,
  requirementsRefs: /^\s{2,}_Requirements:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n\s{2,}_|\n- \[|$)/,
  designRefs: /^\s{2,}_Design:\s*([\s\S]*?)(?=\n\s{2,}\*\*|\n\s{2,}_|\n- \[|$)/,
};

function extractField(block: string, key: string): string {
  const re = BODY_FIELD_RE[key];
  if (!re) return '';
  const m = block.match(re);
  return m ? m[1].trim() : '';
}

function extractFiles(block: string): string[] {
  const raw = extractField(block, 'files');
  if (!raw) return [];
  return raw
    .split('\n')
    .flatMap(line => line.split(','))
    .map(s => s.replace(/^[\s`]+|[\s`]+$/g, '').replace(/^- /, '').trim())
    .filter(Boolean);
}

function extractRefs(raw: string): string[] {
  if (!raw) return [];
  return raw
    .split(',')
    .map(s => s.trim())
    .filter(Boolean);
}

function parseTags(tagStr: string): string[] {
  const tags: string[] = [];
  const re = /\[([^\]]+)\]/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(tagStr)) !== null) {
    tags.push(m[1]);
  }
  return tags;
}

/**
 * Split markdown content into (header lines, task blocks).
 * A task block starts with a `- [ ]` or `- [x]` line and
 * includes all subsequent indented/blank lines up to the
 * next task or end of section.
 */
function splitIntoTaskBlocks(content: string): Array<{ line: string; block: string }> {
  const lines = content.split('\n');
  const results: Array<{ line: string; block: string }> = [];

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (TASK_LINE_RE.test(line)) {
      // Collect the body: lines that are indented, blank between task body lines,
      // or continuation lines, until we hit another task or a heading.
      const bodyLines: string[] = [];
      i++;
      while (i < lines.length) {
        const next = lines[i];
        // Stop at next task checkbox or top-level heading
        if (TASK_LINE_RE.test(next) || /^#{1,6} /.test(next)) break;
        bodyLines.push(next);
        i++;
      }
      results.push({ line, block: bodyLines.join('\n') });
    } else {
      i++;
    }
  }
  return results;
}

export function parseTasks(content: string): ParsedTask[] {
  const blocks = splitIntoTaskBlocks(content);
  return blocks.map(({ line, block }, index) => {
    const m = TASK_LINE_RE.exec(line);
    if (!m) throw new Error(`Unexpected parse failure on line: ${line}`);

    const [, completedChar, id, tagsPart, titleRaw] = m;
    const completed = completedChar === 'x';
    const tags = parseTags(tagsPart);
    const parallel = tags.includes('P');
    const title = titleRaw.trim();

    const doText = extractField(block, 'do');
    const files = extractFiles(block);
    const doneWhen = extractField(block, 'doneWhen');
    const verify = extractField(block, 'verify');
    const commit = extractField(block, 'commit');
    const reqRaw = extractField(block, 'requirementsRefs');
    const designRaw = extractField(block, 'designRefs');

    return {
      index,
      id,
      title,
      completed,
      parallel,
      tags,
      body: {
        do: doText,
        files,
        doneWhen,
        verify,
        commit,
        requirementsRefs: reqRaw ? extractRefs(reqRaw) : undefined,
        designRefs: designRaw ? extractRefs(designRaw) : undefined,
      },
    } satisfies ParsedTask;
  });
}

/**
 * Flip the checkbox for the task at zero-based `index` from `[ ]` to `[x]`.
 * Returns the updated content string.
 */
export function markTaskComplete(content: string, index: number): string {
  const lines = content.split('\n');
  let taskCount = 0;
  for (let i = 0; i < lines.length; i++) {
    if (TASK_LINE_RE.test(lines[i])) {
      if (taskCount === index) {
        lines[i] = lines[i].replace(/^(- \[) (\])/, '$1x$2');
        return lines.join('\n');
      }
      taskCount++;
    }
  }
  return content;
}

const MAX_PARALLEL_GROUP_SIZE = 5;

/**
 * Find runs of consecutive parallel (`[P]`) tasks.
 * Each group contains at most MAX_PARALLEL_GROUP_SIZE tasks.
 */
export function detectParallelGroups(tasks: ParsedTask[]): ParallelGroup[] {
  const groups: ParallelGroup[] = [];
  let i = 0;

  while (i < tasks.length) {
    if (!tasks[i].parallel) {
      i++;
      continue;
    }

    // Start of a parallel run
    const runStart = i;
    while (i < tasks.length && tasks[i].parallel) {
      i++;
    }
    const runEnd = i; // exclusive

    // Slice the run into chunks of MAX_PARALLEL_GROUP_SIZE
    for (let start = runStart; start < runEnd; start += MAX_PARALLEL_GROUP_SIZE) {
      const end = Math.min(start + MAX_PARALLEL_GROUP_SIZE, runEnd);
      const indices = Array.from({ length: end - start }, (_, k) => tasks[start + k].index);
      groups.push({
        startIndex: tasks[start].index,
        endIndex: tasks[end - 1].index,
        taskIndices: indices,
      });
    }
  }

  return groups;
}
