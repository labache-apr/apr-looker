#!/usr/bin/env python3
"""Lint LookML for required documentation metadata.

Enforces the rules in docs/STYLEGUIDE.md §1 against blocks that have been
added or modified in the current branch (vs. a base ref). Legacy debt in
untouched blocks does not fail the build.

Usage (local):
    python3 scripts/lint_lookml_docs.py [base_ref]
    # default base_ref is origin/master

Exit code: 0 on success, 1 on lint failure, 2 on internal error.
"""
from __future__ import annotations

import re
import subprocess
import sys
from dataclasses import dataclass
from pathlib import Path

try:
    import lkml
except ImportError:
    sys.stderr.write("error: `lkml` package not installed. `pip install lkml`\n")
    sys.exit(2)

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_BASE = "origin/master"

# Path patterns that are NOT standalone views (extension targets).
# These don't need a primary key and don't need the full §6 header — but
# their non-hidden fields still need descriptions.
EXTENSION_TARGET_DIRS = ("views/structs/", "views/custom_fields/")

# Required lines in the §6 view header for a brand-new standalone view.
REQUIRED_HEADER_KEYS = ("View:", "Source:", "Grain:", "Owner:")


@dataclass
class Issue:
    file: str
    line: int
    rule: str
    message: str

    def __str__(self) -> str:
        return f"{self.file}:{self.line}: [{self.rule}] {self.message}"


# ─── Diff parsing ────────────────────────────────────────────────────

def changed_files(base_ref: str) -> dict[str, set[int] | None]:
    """Return {path: changed_line_numbers, or None if file is brand new}.

    Only includes added/modified .lkml/.lookml files. Deletions and
    renames are excluded — there's nothing to lint there.
    """
    cmd = [
        "git", "diff", "--unified=0", "--diff-filter=AM",
        f"{base_ref}...HEAD", "--", "*.lkml", "*.lookml",
    ]
    proc = subprocess.run(cmd, capture_output=True, text=True, check=True)
    files: dict[str, set[int] | None] = {}
    current: str | None = None
    is_new = False
    hunk_re = re.compile(r"^@@ -\d+(?:,\d+)? \+(\d+)(?:,(\d+))? @@")
    for line in proc.stdout.splitlines():
        if line.startswith("diff --git "):
            current = None
            is_new = False
        elif line.startswith("new file mode"):
            is_new = True
        elif line.startswith("+++ b/"):
            current = line[6:]
            files[current] = None if is_new else set()
        elif current and not is_new and (m := hunk_re.match(line)):
            start = int(m.group(1))
            count = int(m.group(2)) if m.group(2) is not None else 1
            if count == 0:  # pure deletion at this anchor — nothing added
                continue
            files[current].update(range(start, start + count))
    return files


# ─── Block line locations ────────────────────────────────────────────

# Find the line where a block opens. Used so we can report a useful
# location and check whether the block overlaps the changed-line set.
BLOCK_OPEN_RE = re.compile(
    r"^(\s*)(view|explore|dimension|measure|dimension_group)\s*:\s*"
    r"([A-Za-z_][\w]*)\s*\{",
)


def block_line_map(text: str) -> dict[tuple[str, str], tuple[int, int]]:
    """Map (kind, name) → (open_line, close_line) using brace matching.

    Best-effort: skips brace counting inside `... ;;` SQL blocks and
    Liquid `{% %}` / `{{ }}` templates. Good enough for the lint we
    care about; we never need exact AST nesting, only "which block does
    this line belong to?".
    """
    lines = text.splitlines()
    result: dict[tuple[str, str], tuple[int, int]] = {}
    in_sql = False
    open_stack: list[tuple[str, str, int]] = []  # (kind, name, open_line)
    for i, raw in enumerate(lines, start=1):
        # crude `;;` ends any sql block on this line
        line = raw
        if in_sql:
            if ";;" in line:
                in_sql = False
                line = line.split(";;", 1)[1]
            else:
                continue
        # detect `sql:` start (must come after we've stripped any prior ;;)
        if re.search(r"\b(sql|html)\s*:", line):
            # everything after the colon is in sql until ;;
            after = line.split(":", 1)[1]
            if ";;" in after:
                line = after.split(";;", 1)[1]
            else:
                in_sql = True
                continue
        # strip liquid templates and quoted strings to avoid false braces
        line = re.sub(r"\{\{.*?\}\}|\{%.*?%\}|\"(?:[^\"\\]|\\.)*\"", "", line)
        # block open?
        m = BLOCK_OPEN_RE.match(raw)
        if m:
            open_stack.append((m.group(2), m.group(3), i))
            # consume the `{` we just matched so the brace count below
            # doesn't see it again
            line = line.split("{", 1)[1] if "{" in line else line
        # remaining { and } on the line
        for ch in line:
            if ch == "{":
                # untracked nested anonymous block — push placeholder so
                # close braces still pair up
                open_stack.append(("_", "_", i))
            elif ch == "}":
                if not open_stack:
                    continue
                kind, name, open_line = open_stack.pop()
                if kind != "_":
                    result[(kind, name)] = (open_line, i)
    return result


# ─── Rule checks ─────────────────────────────────────────────────────

def is_yes(value) -> bool:
    return str(value).strip().lower() == "yes"


def block_changed(
    block_range: tuple[int, int] | None,
    changed: set[int] | None,
) -> bool:
    if changed is None:  # whole file is new
        return True
    if block_range is None:  # parser disagreement — be safe, treat as changed
        return True
    start, end = block_range
    return any(start <= ln <= end for ln in changed)


def check_field(
    file: str,
    kind: str,
    field: dict,
    line: int,
    require_value_format: bool,
) -> list[Issue]:
    issues: list[Issue] = []
    name = field.get("name", "<anonymous>")
    label = f"{kind} {name}"
    hidden = is_yes(field.get("hidden"))
    tags = field.get("tags", []) or []

    # Rule: deprecated → must be hidden
    if "deprecated" in tags and not hidden:
        issues.append(Issue(
            file, line, "deprecated-must-hide",
            f"{label} is tagged 'deprecated' but not hidden",
        ))

    if hidden:
        return issues  # remaining rules apply to visible fields only

    # Rule: visible field must have description
    desc = (field.get("description") or "").strip()
    if not desc:
        issues.append(Issue(
            file, line, "missing-description",
            f"{label} has no `description:`",
        ))

    # Rule: visible measure must have value_format[_name].
    # Exemption: count / count_distinct rely on Looker's default formatting.
    if require_value_format:
        mtype = (field.get("type") or "").strip().lower()
        if mtype not in ("count", "count_distinct"):
            if not (field.get("value_format_name") or field.get("value_format")):
                issues.append(Issue(
                    file, line, "missing-value-format",
                    f"{label} has no `value_format_name:` or `value_format:`",
                ))

    return issues


def check_explore(
    file: str,
    explore: dict,
    line: int,
) -> list[Issue]:
    issues: list[Issue] = []
    name = explore.get("name", "<anonymous>")
    label = f"explore {name}"
    for required in ("description", "label", "group_label"):
        val = (explore.get(required) or "").strip()
        if not val:
            issues.append(Issue(
                file, line, "missing-explore-metadata",
                f"{label} has no `{required}:`",
            ))
    return issues


def check_view_header(file: str, text: str) -> list[Issue]:
    """For brand-new standalone views, require the §6 header keys."""
    # §6 applies to view files only — not explore files.
    if not file.endswith(".view.lkml"):
        return []
    if any(file.startswith(d) for d in EXTENSION_TARGET_DIRS):
        return []  # extension targets are exempt from full header
    head = "\n".join(text.splitlines()[:40])
    missing = [k for k in REQUIRED_HEADER_KEYS if k not in head]
    if missing:
        return [Issue(
            file, 1, "missing-view-header",
            f"new view file is missing header keys: {', '.join(missing)} "
            f"(see STYLEGUIDE §6)",
        )]
    return []


# ─── Driver ──────────────────────────────────────────────────────────

def lint_file(
    file: str,
    changed: set[int] | None,
) -> list[Issue]:
    # Dashboard files use a YAML-flavored grammar that `lkml` can't parse,
    # and §1's rules don't apply to them anyway.
    if file.endswith(".dashboard.lookml") or file.endswith(".dashboard.lkml"):
        return []
    abs_path = REPO_ROOT / file
    if not abs_path.exists():
        return []  # deleted concurrently with the diff snapshot
    text = abs_path.read_text()

    issues: list[Issue] = []

    # New-file-only: header check
    if changed is None:
        issues.extend(check_view_header(file, text))

    try:
        tree = lkml.load(text)
    except Exception as e:
        # Syntax errors are Spectacles' job; don't double-report.
        sys.stderr.write(f"warning: lkml parse failed for {file}: {e}\n")
        return issues

    line_map = block_line_map(text)

    # Views and their fields
    for view in tree.get("views", []):
        vname = view.get("name", "<anonymous>")
        vrange = line_map.get(("view", vname))
        vline = vrange[0] if vrange else 1

        for field in view.get("dimensions", []):
            frange = line_map.get(("dimension", field.get("name", "")))
            fline = frange[0] if frange else vline
            if not block_changed(frange, changed):
                continue
            issues.extend(check_field(file, "dimension", field, fline,
                                      require_value_format=False))

        for field in view.get("dimension_groups", []):
            frange = line_map.get(("dimension_group", field.get("name", "")))
            fline = frange[0] if frange else vline
            if not block_changed(frange, changed):
                continue
            issues.extend(check_field(file, "dimension_group", field, fline,
                                      require_value_format=False))

        for field in view.get("measures", []):
            frange = line_map.get(("measure", field.get("name", "")))
            fline = frange[0] if frange else vline
            if not block_changed(frange, changed):
                continue
            issues.extend(check_field(file, "measure", field, fline,
                                      require_value_format=True))

    # Explores
    for explore in tree.get("explores", []):
        ename = explore.get("name", "<anonymous>")
        erange = line_map.get(("explore", ename))
        eline = erange[0] if erange else 1
        if not block_changed(erange, changed):
            continue
        issues.extend(check_explore(file, explore, eline))

    return issues


def main(argv: list[str]) -> int:
    base = argv[1] if len(argv) > 1 else DEFAULT_BASE
    try:
        files = changed_files(base)
    except subprocess.CalledProcessError as e:
        sys.stderr.write(f"error: git diff failed: {e.stderr}\n")
        return 2

    if not files:
        print("lint-lookml-docs: no LookML changes vs", base)
        return 0

    all_issues: list[Issue] = []
    for path, changed in files.items():
        all_issues.extend(lint_file(path, changed))

    # Dedupe: when multiple views in one file have same-named fields,
    # the line lookup may collapse them. Report each unique issue once.
    seen: set[tuple[str, int, str, str]] = set()
    unique: list[Issue] = []
    for issue in all_issues:
        key = (issue.file, issue.line, issue.rule, issue.message)
        if key in seen:
            continue
        seen.add(key)
        unique.append(issue)

    if unique:
        print(f"lint-lookml-docs: {len(unique)} issue(s)\n")
        for issue in sorted(unique, key=lambda i: (i.file, i.line)):
            print(f"  {issue}")
        print("\nSee docs/STYLEGUIDE.md §1 for required metadata.")
        return 1

    print(f"lint-lookml-docs: passed ({len(files)} file(s) scanned)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
