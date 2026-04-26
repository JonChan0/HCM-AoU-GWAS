#!/usr/bin/env python3
"""Check all .ipynb files recursively for non-empty output cells and sensitive strings."""

import json
import re
import sys
from pathlib import Path

SENSITIVE_PATTERNS = [
    r"terra-vpc",
    r"jon126",
    r"jonathan\.chan",
    r"protonmail",
    r"@gmail\.com",
    r"@outlook\.com",
    r"ghp_[A-Za-z0-9]+",          # GitHub PAT
    r"sk-[A-Za-z0-9]{20,}",       # OpenAI-style key
    r"AIza[A-Za-z0-9_\-]{35}",    # Google API key
    r"(?i)password\s*=\s*['\"].+?['\"]",
    r"(?i)secret\s*=\s*['\"].+?['\"]",
    r"(?i)api[_\-]?key\s*=\s*['\"].+?['\"]",
    r"\b(?:\d{1,3}\.){3}\d{1,3}\b",  # IP address
]

_compiled = [(p, re.compile(p)) for p in SENSITIVE_PATTERNS]


def _cell_text(cell: dict) -> str:
    """Flatten source + all output text for a cell."""
    parts = []
    src = cell.get("source", [])
    parts.append("".join(src) if isinstance(src, list) else src)
    for out in cell.get("outputs", []):
        for key in ("text", "traceback"):
            val = out.get(key, [])
            parts.append("".join(val) if isinstance(val, list) else val)
        data = out.get("data", {})
        for mime_val in data.values():
            parts.append("".join(mime_val) if isinstance(mime_val, list) else str(mime_val))
    return "\n".join(parts)


def check_notebook(path: Path) -> tuple[list[dict], list[dict]]:
    """Return (output_hits, sensitive_hits)."""
    try:
        nb = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError) as e:
        print(f"  ERROR reading {path}: {e}")
        return [], []

    output_hits = []
    sensitive_hits = []

    for i, cell in enumerate(nb.get("cells", [])):
        outputs = cell.get("outputs", [])
        if outputs:
            output_hits.append({
                "cell_idx": i,
                "cell_type": cell.get("cell_type", "unknown"),
                "n_outputs": len(outputs),
                "output_types": list({o.get("output_type", "?") for o in outputs}),
            })

        text = _cell_text(cell)
        for pattern, rx in _compiled:
            for m in rx.finditer(text):
                sensitive_hits.append({
                    "cell_idx": i,
                    "cell_type": cell.get("cell_type", "unknown"),
                    "pattern": pattern,
                    "match": m.group(),
                })

    return output_hits, sensitive_hits


def main():
    root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(".")
    notebooks = sorted(root.rglob("*.ipynb"))

    if not notebooks:
        print(f"No .ipynb files found under {root}")
        return

    total_files = len(notebooks)
    dirty_files = 0
    total_output_cells = 0
    total_sensitive = 0

    for nb_path in notebooks:
        rel = nb_path.relative_to(root)
        output_hits, sensitive_hits = check_notebook(nb_path)

        file_flagged = bool(output_hits or sensitive_hits)
        if file_flagged:
            dirty_files += 1

        if output_hits:
            total_output_cells += len(output_hits)
            print(f"\n[OUTPUT]    {rel}")
            for h in output_hits:
                print(f"  cell {h['cell_idx']:>3} ({h['cell_type']}) — "
                      f"{h['n_outputs']} output(s): {', '.join(h['output_types'])}")

        if sensitive_hits:
            total_sensitive += len(sensitive_hits)
            if not output_hits:
                print(f"\n[SENSITIVE] {rel}")
            for h in sensitive_hits:
                print(f"  cell {h['cell_idx']:>3} ({h['cell_type']}) — "
                      f"pattern '{h['pattern']}' matched: {h['match']!r}")

        if not file_flagged:
            print(f"[clean]     {rel}")

    print(f"\n{'='*60}")
    print(f"Scanned          : {total_files} notebook(s)")
    print(f"Flagged files    : {dirty_files}")
    print(f"Output cells     : {total_output_cells}")
    print(f"Sensitive matches: {total_sensitive}")


if __name__ == "__main__":
    main()
