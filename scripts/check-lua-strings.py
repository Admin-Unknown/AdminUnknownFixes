"""Sanity check that bulk string-literal edits did not damage the Lua source.

Not a parser. It walks each file character by character, tracking whether it is
inside a short string, a long bracket string or a comment, and reports a file
when a string is left open at end of line or a bracket ends up unbalanced -
the two ways a bad search-and-replace over quoted names shows up.

    python scripts/check-lua-strings.py
"""

import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SKIP = {"othermodsource"}


def check(path):
    text = path.read_text(encoding="utf-8", errors="replace")
    problems = []
    depth = {"(": 0, "[": 0, "{": 0}
    closer = {")": "(", "]": "[", "}": "{"}
    i, line, quote, long_bracket = 0, 1, None, False
    while i < len(text):
        ch = text[i]
        if ch == "\n":
            if quote is not None:
                problems.append(f"line {line}: unterminated {quote} string")
                quote = None
            line += 1
            i += 1
            continue
        if quote is not None:
            if ch == "\\":
                i += 2
                continue
            if ch == quote:
                quote = None
            i += 1
            continue
        if long_bracket:
            if text.startswith("]]", i):
                long_bracket = False
                i += 2
                continue
            i += 1
            continue
        if text.startswith("--[[", i):
            long_bracket = True
            i += 4
            continue
        if text.startswith("--", i):
            while i < len(text) and text[i] != "\n":
                i += 1
            continue
        if text.startswith("[[", i):
            long_bracket = True
            i += 2
            continue
        if ch in "\"'":
            quote = ch
            i += 1
            continue
        if ch in depth:
            depth[ch] += 1
        elif ch in closer:
            depth[closer[ch]] -= 1
            if depth[closer[ch]] < 0:
                problems.append(f"line {line}: unmatched {ch}")
                depth[closer[ch]] = 0
        i += 1

    if quote is not None:
        problems.append("end of file: unterminated string")
    for bracket, count in depth.items():
        if count:
            problems.append(f"end of file: {count} unclosed {bracket}")
    return problems


def main():
    failures = 0
    checked = 0
    for path in sorted(ROOT.rglob("*.lua")):
        if any(part in SKIP for part in path.parts):
            continue
        checked += 1
        problems = check(path)
        if problems:
            failures += 1
            print(path.relative_to(ROOT))
            for problem in problems[:5]:
                print(f"    {problem}")
    print(f"\n{checked} files checked, {failures} with problems")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
