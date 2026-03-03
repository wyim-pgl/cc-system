---
name: code-polish
description: >
  Code improvement agent that scans files and suggests improvements for readability,
  performance, error handling, security, and best practices. Targets the bioinformatics
  stack: Python, Bash, R, and Nextflow. For each issue found, explains the problem,
  shows the current code, and provides an improved version. Auto-applies safe fixes
  (formatting, naming, trivial patterns) and asks before applying substantive changes.
  Use when the user asks to: polish code, review code quality, improve code, clean up
  a script, check for best practices, optimize code, scan for issues, lint, refactor
  for readability, or fix code smells. Triggers on phrases like "polish", "clean up",
  "improve this code", "code quality", "best practices check", "refactor".
---

# Code Polish

## Workflow

1. **Identify targets** — determine which files to scan (user-specified or inferred from context)
2. **Quick scan** — run `scripts/scan.py` to detect pattern-based issues
3. **Deep review** — read each file and apply judgment-based analysis beyond regex patterns
4. **Report** — present findings grouped by category and severity
5. **Apply fixes** — auto-apply `safe_fix` severity items; ask before applying `suggestion` items

## Running the Scanner

```bash
python <skill-dir>/scripts/scan.py <file_or_directory> [--lang python|bash|r|nextflow]
```

Output is JSON with `findings` array. Each finding has: `rule`, `category`, `severity`, `line`, `code`, `message`, `file`.

Severity levels:
- `safe_fix` — auto-apply without asking (trivial, non-breaking: `== True` → truthy, `== None` → `is None`, formatting)
- `suggestion` — show the issue, propose fix, ask user before applying
- `info` — report only, no action needed (TODOs, notes)

## Deep Review Checklist

After the scanner runs, manually review for issues patterns can't catch:

- **Function complexity** — functions > 50 lines or > 3 nesting levels
- **Dead code** — unused imports, unreachable branches, commented-out blocks
- **Naming clarity** — vague names (`data`, `tmp`, `x`, `result`) in non-trivial scopes
- **Repeated code** — near-duplicate blocks that should be extracted
- **Missing error handling** — file I/O without try/except, subprocess without error check
- **Data pipeline issues** — Pandas anti-patterns, inefficient R loops, missing NA handling
- **Documentation gaps** — public functions without any indication of purpose (only flag if function purpose is genuinely unclear from name + context)

Consult `references/categories.md` for the full checklist organized by language and category.

## Report Format

Present findings as a structured report, then show inline diffs for each issue:

```markdown
## Code Polish Report: `<filename>`

### Summary
| Category       | Issues |
|---------------|--------|
| Readability    | N      |
| Performance    | N      |
| Error Handling | N      |
| Best Practices | N      |
| Security       | N      |

### Issues

#### 1. [Category] Issue title (line N) — severity

**Problem:** Brief explanation of why this is an issue.

**Current code:**
\`\`\`python
# the problematic code
\`\`\`

**Improved:**
\`\`\`python
# the fixed code
\`\`\`
```

## Applying Fixes

- **safe_fix items**: Apply immediately using the Edit tool. Inform the user what was auto-applied in the report summary.
- **suggestion items**: Present in the report. After the full report, ask the user which suggestions to apply. Apply selected fixes.
- **info items**: Report only. No action.

When applying multiple fixes to the same file, apply from bottom to top (highest line number first) to preserve line numbers for subsequent edits.

## Scope Control

- If the user specifies files, scan only those files
- If the user says "polish this" with no file context, check for recently modified files in the working directory
- Do not scan generated files, vendored dependencies, or data files
- Skip files larger than 5000 lines — suggest splitting instead
