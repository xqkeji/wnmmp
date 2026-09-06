#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
check-bat.py - static checker for the wnmmp .bat sources.

Why this exists: cmd.exe parses .bat files byte-wise using code page 936
(GBK) while the files are UTF-8, and it re-tokenises certain lines. That
combination produces "'...' is not recognised" phantom errors that only
show up on a real Windows machine (and only on rarely taken branches).
This script finds those patterns without running cmd.exe.

Usage:  python tools/check-bat.py [--strict]

Exit code 0 when no hard error is found (warnings do not fail the run).
"""
import glob
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STRICT = "--strict" in sys.argv

CJK = re.compile(r"[\u3000-\u9fff\uff00-\uffef]")
LABEL_DEF = re.compile(r"^:([A-Za-z0-9_.\-]+)", re.I)
CALL_GOTO = re.compile(
    r"^\s*(?:call|goto)\s+(?::?\s*)?([A-Za-z0-9_.\-]+)", re.I
)

# Legal "!" constructs that are NOT stray literals.
BANG_OK = [
    re.compile(r"![A-Za-z_][A-Za-z0-9_]*!"),          # !VAR!
    re.compile(r"![A-Za-z_][A-Za-z0-9_]*:[^!]*!"),    # !VAR:x=y! / !VAR:~n,m!
    re.compile(r"!%~[1-9]!?"),                        # !%~3! / !%~3
]


def decode(raw):
    return raw.decode("utf-8", errors="replace")


def check_file(path):
    errs, warns = [], []
    raw = open(path, "rb").read()
    name = os.path.relpath(path, ROOT).replace("\\", "/")

    # 1/2. encoding: UTF-8 without BOM and pure CRLF.
    if raw[:3] == b"\xef\xbb\xbf":
        errs.append("BOM present (breaks @echo off)")
    crlf = raw.count(b"\r\n")
    lf_only = raw.count(b"\n") - crlf
    if lf_only:
        errs.append("LF-only line endings: %d (findstr/for /f break)" % lf_only)

    text = decode(raw)
    lines = text.replace("\r\n", "\n").split("\n")

    # index of labels and of call/goto targets
    labels = {}
    for i, ln in enumerate(lines):
        m = LABEL_DEF.match(ln.strip())
        if m:
            labels.setdefault(m.group(1).lower(), i)

    for i, ln in enumerate(lines):
        s = ln.strip()
        if not s:
            continue
        low = s.lower()

        # 3. quote parity
        if s.count('"') % 2 == 1:
            errs.append("L%d odd number of double quotes: %s" % (i + 1, s[:70]))

        # 4. stray "!" on a line that also uses !VAR!
        #     Skipped for REM/:: (never re-parsed) and for anything inside
        #     double quotes (findstr /c:"!" style literal tests).
        if "!" in s and not re.match(r"^(rem|::)\b", low):
            probe = re.sub(r'"[^"]*"', "", s)   # drop quoted segments
            for rx in BANG_OK:
                probe = rx.sub("", probe)
            if "!" in probe:
                errs.append("L%d stray literal '!': %s" % (i + 1, s[:70]))

        # 5. single-line if/for/&&/|| followed by an unquoted Chinese echo
        if re.match(r"^(if|for)\b", low) or "&&" in s or "||" in s:
            m = re.search(r"\becho\s+(.+)$", s, re.I)
            if m and CJK.search(m.group(1)) and '"' not in m.group(1):
                errs.append(
                    "L%d single-line if/for + unquoted Chinese echo: %s"
                    % (i + 1, s[:70])
                )

        # 6. Chinese text right in front of a CALL/GOTO target label
        m = CALL_GOTO.match(s)
        if m and m.group(1).lower() in labels:
            j = labels[m.group(1).lower()]
            for k in range(max(0, j - 6), j):
                t = lines[k].strip()
                # REM is a no-op; `set "X=..."` never phantoms, so only bare
                # commands (echo/call/...) sitting above a label are a risk.
                if not t or t.lower().startswith("rem") or t.startswith("::"):
                    continue
                if re.match(r'^set\s+"[^"]*"\s*$', t, re.I):
                    continue
                # A quoted ECHO ("...") is one token, so cmd never re-tokenises
                # its contents -- this is the pattern register-path.bat relies on
                # and it has never produced a phantom. Skip it.
                if re.match(r'^echo\s+"', t, re.I):
                    continue
                if CJK.search(t):
                    warns.append(
                        "L%d non-ASCII line just above label :%s -> %s"
                        % (k + 1, m.group(1), t[:50])
                    )
                    break

    # 7. consecutive in-block Chinese echo (byte-offset drift risk)
    run = 0
    for i, ln in enumerate(lines):
        s = ln.strip()
        # A quoted ECHO is immune (single token); only unquoted Chinese ECHO
        # lines can be cut by cmd's character/byte boundary drift.
        is_cjk_echo = bool(re.match(r"^echo\s+", s, re.I)) and CJK.search(s)
        if is_cjk_echo and '"' not in s:
            run += 1
            if run >= 2:
                warns.append(
                    "L%d consecutive unquoted Chinese echo (%d in a row) - "
                    "use set \"MSGn=...\" + echo !MSGn!" % (i + 1, run)
                )
        elif not s or s.startswith(")"):
            run = 0
        elif not re.match(r"^(rem|::|echo\b)", s, re.I):
            run = 0

    return name, errs, warns


def main():
    files = sorted(glob.glob(os.path.join(ROOT, "**", "*.bat"), recursive=True))
    total_e = total_w = 0
    for f in files:
        name, errs, warns = check_file(f)
        if errs or warns:
            print("=== %s" % name)
            for e in errs:
                print("  [ERROR] %s" % e)
            for w in warns:
                print("  [warn ] %s" % w)
        total_e += len(errs)
        total_w += len(warns)

    print("\nscanned %d .bat files: %d error(s), %d warning(s)" % (
        len(files), total_e, total_w))
    if total_e or (STRICT and total_w):
        sys.exit(1)


if __name__ == "__main__":
    main()
