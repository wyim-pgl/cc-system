#!/usr/bin/env python3
"""
Code Polish Scanner — Quick static analysis for common issues.

Scans files for low-hanging-fruit issues that can be auto-detected via patterns.
Outputs JSON to stdout for Claude to consume and present.

Usage:
    python scan.py <file_or_directory> [--lang python|bash|r|nextflow]

Detects language from file extension if --lang not given.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

LANG_MAP = {
    ".py": "python",
    ".sh": "bash",
    ".bash": "bash",
    ".R": "r",
    ".r": "r",
    ".Rmd": "r",
    ".nf": "nextflow",
    ".config": "nextflow",
}

# Each rule: (id, category, severity, pattern_regex, message, lang_filter)
# severity: "safe_fix" (auto-apply), "suggestion" (ask), "info" (report only)
RULES = [
    # ── Python ──
    ("PY001", "readability", "safe_fix",
     r"^(\s*)if (.+) == True:",
     "Redundant `== True` comparison", "python"),
    ("PY002", "readability", "safe_fix",
     r"^(\s*)if (.+) == False:",
     "Redundant `== False` comparison — use `not`", "python"),
    ("PY003", "readability", "safe_fix",
     r"^(\s*)if (.+) == None:",
     "Use `is None` instead of `== None`", "python"),
    ("PY004", "readability", "safe_fix",
     r"^(\s*)if (.+) != None:",
     "Use `is not None` instead of `!= None`", "python"),
    ("PY005", "best_practice", "suggestion",
     r"^\s*import os\b",
     "Consider `pathlib` for path operations if using os.path", "python"),
    ("PY006", "error_handling", "suggestion",
     r"^\s*except\s*:",
     "Bare `except:` catches all exceptions including SystemExit/KeyboardInterrupt", "python"),
    ("PY007", "performance", "suggestion",
     r"\.iterrows\(\)",
     "Pandas `iterrows()` is slow — consider vectorized operations", "python"),
    ("PY008", "readability", "safe_fix",
     r"^\s*print\(.+%\s",
     "Use f-strings instead of % formatting", "python"),
    ("PY009", "security", "suggestion",
     r"\bos\.system\s*\(",
     "Use `subprocess.run()` instead of `os.system()`", "python"),
    ("PY010", "security", "suggestion",
     r"\beval\s*\(",
     "Avoid `eval()` — potential code injection risk", "python"),
    ("PY011", "best_practice", "suggestion",
     r"def \w+\([^)]*=\s*\[\]",
     "Mutable default argument — use `None` and assign inside function", "python"),
    ("PY012", "readability", "info",
     r"^\s*#.*TODO",
     "TODO comment found", "python"),
    ("PY013", "performance", "suggestion",
     r"^\s*for .+ in range\(len\(",
     "Use `enumerate()` instead of `range(len())`", "python"),
    ("PY014", "readability", "safe_fix",
     r'^\s*["\']password["\']\s*[:=]',
     "Possible hardcoded credential", "python"),
    ("PY015", "performance", "suggestion",
     r"\.append\(",
     "List append in loop — consider list comprehension if building a list", "python"),

    # ── Bash ──
    ("SH001", "robustness", "safe_fix",
     r"^#!/bin/bash\s*$",
     "Add `set -euo pipefail` after shebang for safety", "bash"),
    ("SH002", "best_practice", "safe_fix",
     r"`[^`]+`",
     "Use `$(command)` instead of backticks", "bash"),
    ("SH003", "best_practice", "suggestion",
     r"\bcat\s+\S+\s*\|\s*grep\b",
     "Useless `cat` — use `grep pattern file` directly", "bash"),
    ("SH004", "robustness", "suggestion",
     r'\$\w+[^"]',
     "Unquoted variable — quote `\"$var\"` to prevent word splitting", "bash"),
    ("SH005", "best_practice", "suggestion",
     r"^\s*\[\s+",
     "Use `[[ ]]` instead of `[ ]` for conditionals", "bash"),
    ("SH006", "security", "suggestion",
     r"\beval\b",
     "Avoid `eval` in shell scripts — potential injection risk", "bash"),

    # ── R ──
    ("R001", "best_practice", "safe_fix",
     r"^\s*\w+\s*=\s*(?!function|if|for|while|NULL|NA|TRUE|FALSE|c\()",
     "Use `<-` for assignment instead of `=`", "r"),
    ("R002", "performance", "suggestion",
     r"\b1:length\(",
     "Use `seq_along()` or `seq_len()` — `1:length(x)` fails when length is 0", "r"),
    ("R003", "performance", "suggestion",
     r"\bsapply\s*\(",
     "Consider `vapply()` over `sapply()` for type-safe return values", "r"),
    ("R004", "performance", "suggestion",
     r"\brbind\s*\(",
     "Repeated `rbind()` in loops is slow — collect in list then `do.call(rbind, ...)`", "r"),

    # ── Nextflow ──
    ("NF001", "best_practice", "suggestion",
     r"publishDir\s",
     "Ensure `publishDir` has explicit `mode:` parameter", "nextflow"),
    ("NF002", "robustness", "suggestion",
     r"process\s+\w+\s*\{",
     "Consider adding `errorStrategy` and resource directives", "nextflow"),
]


def detect_lang(filepath):
    ext = Path(filepath).suffix
    return LANG_MAP.get(ext)


def scan_file(filepath, lang=None):
    if lang is None:
        lang = detect_lang(filepath)
    if lang is None:
        return []

    try:
        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            lines = f.readlines()
    except (IOError, OSError) as e:
        print(f"Warning: cannot read {filepath}: {e}", file=sys.stderr)
        return []

    findings = []
    for i, line in enumerate(lines, 1):
        for rule_id, category, severity, pattern, message, rule_lang in RULES:
            if rule_lang != lang:
                continue
            if re.search(pattern, line):
                findings.append({
                    "rule": rule_id,
                    "category": category,
                    "severity": severity,
                    "line": i,
                    "code": line.rstrip(),
                    "message": message,
                    "file": str(filepath),
                })
    return findings


def scan_path(target, lang=None):
    target = Path(target)
    all_findings = []

    if target.is_file():
        all_findings.extend(scan_file(str(target), lang))
    elif target.is_dir():
        for ext in LANG_MAP:
            for fp in target.rglob(f"*{ext}"):
                file_lang = lang or detect_lang(str(fp))
                all_findings.extend(scan_file(str(fp), file_lang))
    else:
        print(f"Error: {target} not found", file=sys.stderr)
        sys.exit(1)

    return all_findings


def main():
    parser = argparse.ArgumentParser(description="Code Polish Scanner")
    parser.add_argument("target", help="File or directory to scan")
    parser.add_argument("--lang", choices=["python", "bash", "r", "nextflow"],
                        help="Force language (auto-detected from extension otherwise)")
    args = parser.parse_args()

    findings = scan_path(args.target, args.lang)

    # Sort by file, then line number
    findings.sort(key=lambda f: (f["file"], f["line"]))

    output = {
        "total": len(findings),
        "by_severity": {
            "safe_fix": sum(1 for f in findings if f["severity"] == "safe_fix"),
            "suggestion": sum(1 for f in findings if f["severity"] == "suggestion"),
            "info": sum(1 for f in findings if f["severity"] == "info"),
        },
        "by_category": {},
        "findings": findings,
    }

    for f in findings:
        cat = f["category"]
        output["by_category"][cat] = output["by_category"].get(cat, 0) + 1

    json.dump(output, sys.stdout, indent=2)
    print()


if __name__ == "__main__":
    main()
