# Code Polish Categories

## Table of Contents
1. [Readability](#readability)
2. [Performance](#performance)
3. [Error Handling & Robustness](#error-handling--robustness)
4. [Best Practices by Language](#best-practices-by-language)
5. [Security](#security)

---

## Readability

### Naming
- Variables/functions: descriptive, intention-revealing names
- Avoid abbreviations except widely-known ones (`df`, `idx`, `seq`, `chr`)
- Boolean variables: use `is_`, `has_`, `should_` prefixes
- Constants: `UPPER_SNAKE_CASE`

### Structure
- Functions > 50 lines: consider splitting
- Nesting > 3 levels: refactor with early returns or extraction
- Magic numbers/strings: extract to named constants
- Dead code: remove commented-out blocks, unused imports, unreachable branches

### Simplification patterns
- Nested if/else → early return / guard clauses
- Manual list building → list comprehension (when clearer)
- Repeated dict key access → variable extraction
- `if x == True` → `if x`
- String concatenation in loops → `join()` or f-strings

---

## Performance

### Python-specific
- `for` loop appending → list comprehension or generator
- Repeated `in` checks on list → convert to `set`
- Reading entire file when iterating lines → use iterator
- Pandas: `iterrows()` → vectorized operations or `apply()`
- Pandas: repeated `df[col]` → extract column once
- Nested loops for matching → dict/set lookup
- String concatenation in loop → `"".join(parts)`
- `os.path` chains → `pathlib.Path`

### Bash-specific
- Parsing `ls` output → glob patterns or `find`
- `cat file | grep` → `grep file` (useless cat)
- Repeated subshell calls in loops → batch processing
- Not quoting variables → quote `"$var"` to prevent word splitting

### R-specific
- Growing vectors in loop → pre-allocate or use `lapply`/`vapply`
- `rbind()` in loop → `do.call(rbind, list)` or `data.table::rbindlist`
- `for` loop over rows → vectorized operations

### I/O & Memory
- Loading entire large file → chunked/streaming processing
- Uncompressed intermediate files → use gzip where appropriate
- Sequential independent tasks → parallel execution opportunities

---

## Error Handling & Robustness

### Input validation
- Check file existence before processing
- Validate expected columns/fields in data
- Handle empty inputs gracefully
- Type checking at function boundaries (public APIs)

### Error handling patterns
- Bare `except:` → catch specific exceptions
- Silent failures → log or raise with context
- Missing `finally` for cleanup → use context managers (`with`)
- Subprocess calls without error checking → check return codes

### Edge cases
- Empty sequences/dataframes
- Missing values / NaN handling
- File encoding issues (specify `encoding='utf-8'`)
- Path separator issues (use `os.path.join` or `pathlib`)

---

## Best Practices by Language

### Python
- Type hints on function signatures (public functions)
- `pathlib` over `os.path` for path manipulation
- Context managers for file/resource handling
- `subprocess.run()` over `os.system()`
- Avoid mutable default arguments (`def f(x=[])` → `def f(x=None)`)
- Use `enumerate()` instead of manual counter
- Use `zip()` instead of index-based parallel iteration

### Bash
- Use `set -euo pipefail` at script top
- Quote all variable expansions
- Use `[[ ]]` over `[ ]` for conditionals
- Use `$(command)` over backticks
- Check command existence with `command -v`
- Use `mktemp` for temporary files
- Trap signals for cleanup

### R
- Use `<-` for assignment (not `=`)
- Explicit `library()` calls at script top
- `seq_along(x)` over `1:length(x)` (handles length-0)
- `vapply` over `sapply` for predictable return types
- Close connections explicitly

### Nextflow
- Use `publishDir` with `mode: 'copy'` or `'link'` explicitly
- Define resource requirements (`cpus`, `memory`, `time`)
- Use `tuple` for multi-file channel outputs
- Error strategy: `errorStrategy 'retry'` with `maxRetries`

---

## Security

- Avoid `eval()`, `exec()`, `os.system()` with user input
- Sanitize file paths (no path traversal via `../`)
- Don't hardcode credentials, tokens, or passwords
- Use `secrets` module for random token generation (not `random`)
- Subprocess: use list form `['cmd', 'arg']` over shell=True
- SQL: parameterized queries over string formatting
