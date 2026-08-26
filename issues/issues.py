#!/usr/bin/env python3
"""
Localized issues helper for redfishopenbmc.

Usage:
  python3 issues/issues.py list [--all] [--open] [--closed] [--json]
  python3 issues/issues.py show <id>
  python3 issues/issues.py close <id> [--reason TEXT]
  python3 issues/issues.py reopen <id>
  python3 issues/issues.py new "Title" [--priority P1] [--type feature] [--estimate 20000] [--labels a,b]
  python3 issues/issues.py stats [--json]
  python3 issues/issues.py validate

No third-party deps. YAML parsing is optional (falls back to regex).
"""
from __future__ import annotations
import argparse
import datetime
import json
import os
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
OPEN_DIR = ROOT / "open"
CLOSED_DIR = ROOT / "closed"
TEMPLATE = ROOT / "TEMPLATE.md"

ID_RE = re.compile(r"^(\d{3})-.*\.md$")
FRONT_RE = re.compile(r"^---\s*\n(.*?)\n---\s*\n", re.DOTALL)

def find_issue_file(id_str: str) -> Path | None:
    pid = f"{int(id_str):03d}"
    for d in (OPEN_DIR, CLOSED_DIR):
        for p in d.glob(f"{pid}-*.md"):
            return p
        # fallback: any file that starts with pid
        for p in d.glob("*.md"):
            m = ID_RE.match(p.name)
            if m and m.group(1) == pid:
                return p
    return None

def parse_frontmatter(text: str) -> dict:
    m = FRONT_RE.search(text)
    if not m:
        return {}
    raw = m.group(1)
    # try yaml if available
    try:
        import yaml  # type: ignore
        data = yaml.safe_load(raw)
        if isinstance(data, dict):
            return data
    except Exception:
        pass
    # fallback: simple key: value lines
    data = {}
    for line in raw.splitlines():
        line=line.strip()
        if not line or line.startswith("#"):
            continue
        if ":" not in line:
            continue
        k, v = line.split(":", 1)
        k=k.strip()
        v=v.strip()
        # unquote
        if (v.startswith('"') and v.endswith('"')) or (v.startswith("'") and v.endswith("'")):
            v=v[1:-1]
        if v == "null":
            v=None
        elif v.startswith("[") and v.endswith("]"):
            inner=v[1:-1].strip()
            if not inner:
                v=[]
            else:
                v=[x.strip().strip('"').strip("'") for x in inner.split(",")]
        data[k]=v
    return data

def parse_issue(path: Path) -> dict:
    text = path.read_text(encoding="utf-8")
    fm = parse_frontmatter(text)
    m = ID_RE.match(path.name)
    file_id = m.group(1) if m else fm.get("id", "?")
    status_dir = "open" if path.parent == OPEN_DIR else "closed" if path.parent == CLOSED_DIR else "?"
    return {
        "path": str(path),
        "file": path.name,
        "dir": status_dir,
        "id": str(fm.get("id", file_id)),
        "title": fm.get("title", path.stem[4:] if len(path.stem)>4 else path.stem),
        "status": fm.get("status", status_dir),
        "priority": fm.get("priority", "?"),
        "type": fm.get("type", "?"),
        "created": fm.get("created", "?"),
        "updated": fm.get("updated", "?"),
        "closed": fm.get("closed", None),
        "assignee": fm.get("assignee", "?"),
        "labels": fm.get("labels", []),
        "estimated_tokens": fm.get("estimated_tokens", "?"),
        "frontmatter": fm,
        "raw": text,
    }

def all_issues(dirs=("open","closed")) -> list[dict]:
    out=[]
    if "open" in dirs:
        for p in sorted(OPEN_DIR.glob("*.md")):
            if p.name in ("README.md",): continue
            if not ID_RE.match(p.name): continue
            out.append(parse_issue(p))
    if "closed" in dirs:
        for p in sorted(CLOSED_DIR.glob("*.md")):
            if not ID_RE.match(p.name): continue
            out.append(parse_issue(p))
    return out

def cmd_list(args):
    if args.all:
        dirs=("open","closed")
    elif args.closed:
        dirs=("closed",)
    else:
        dirs=("open",)
    issues = all_issues(dirs)
    # sort: priority P1->P4 then id
    pri_order={"P1":0,"P2":1,"P3":2,"P4":3}
    issues.sort(key=lambda x: (pri_order.get(str(x["priority"]),9), int(x["id"]) if str(x["id"]).isdigit() else 999))
    if args.json:
        print(json.dumps([{k:v for k,v in i.items() if k not in ("raw","frontmatter")} for i in issues], indent=2))
        return
    if not issues:
        print(f"No issues in {','.join(dirs)}/")
        return
    # table
    print(f"{'ID':<4} {'P':<3} {'TYPE':<8} {'STATUS':<7} {'DIR':<6}  TITLE")
    print("-"*90)
    for i in issues:
        print(f"{str(i['id']):<4} {str(i['priority']):<3} {str(i['type']):<8} {str(i['status']):<7} {i['dir']:<6}  {i['title']}  ({i['file']})")
    print(f"\nTotal: {len(issues)}  (open:{len([x for x in all_issues(('open',))])} closed:{len([x for x in all_issues(('closed',))])})")

def cmd_show(args):
    p = find_issue_file(args.id)
    if not p:
        print(f"Issue #{args.id} not found in open/ or closed/", file=sys.stderr)
        sys.exit(1)
    data = parse_issue(p)
    print(f"File: {p}  (dir={data['dir']})")
    print(f"Frontmatter: {json.dumps(data['frontmatter'], indent=2, default=str)}")
    print("\n--- CONTENT ---\n")
    print(data["raw"])

def cmd_close(args):
    p = find_issue_file(args.id)
    if not p:
        print(f"Issue #{args.id} not found", file=sys.stderr)
        sys.exit(1)
    if p.parent == CLOSED_DIR:
        print(f"Issue #{args.id} already closed at {p}")
        sys.exit(0)
    text = p.read_text(encoding="utf-8")
    today = datetime.date.today().isoformat()
    # patch frontmatter
    def repl_front(m):
        fm_raw = m.group(1)
        # update fields via regex to preserve formatting
        def patch(key, value, raw):
            pat = re.compile(rf"^{re.escape(key)}\s*:.*$", re.MULTILINE)
            replacement = f"{key}: {value}"
            if pat.search(raw):
                return pat.sub(replacement, raw)
            else:
                return raw + f"\n{replacement}"
        fm_raw = patch("status", "closed", fm_raw)
        fm_raw = patch("closed", today, fm_raw)
        fm_raw = patch("updated", today, fm_raw)
        return f"---\n{fm_raw}\n---\n"
    new_text, n = FRONT_RE.subn(repl_front, text, count=1)
    # append closed note if reason
    if args.reason:
        if "## Closed Criteria" in new_text:
            new_text = new_text.replace("## Closed Criteria", f"## Closed Criteria\n\n- Resolution: {args.reason}\n- Closed: {today}\n")
        else:
            new_text += f"\n## Closed\n\n- Resolution: {args.reason}\n- Closed: {today}\n"
    else:
        # at least add closed timestamp in Progress Log
        if "## Progress Log" in new_text:
            new_text = new_text.replace("## Progress Log", f"## Progress Log\n\n- {today} — Closed via issues.py (moved open → closed).")
    CLOSED_DIR.mkdir(parents=True, exist_ok=True)
    dest = CLOSED_DIR / p.name
    if dest.exists():
        print(f"Destination {dest} already exists — abort", file=sys.stderr)
        sys.exit(1)
    # write patched file to dest, remove src
    dest.write_text(new_text, encoding="utf-8")
    p.unlink()
    print(f"Closed #{args.id}: {p.name} → {dest}")
    print(f"Remember to update progress/journal.md and git commit.")

def cmd_reopen(args):
    p = find_issue_file(args.id)
    if not p:
        print(f"Issue #{args.id} not found", file=sys.stderr)
        sys.exit(1)
    if p.parent == OPEN_DIR:
        print(f"Issue #{args.id} already open at {p}")
        sys.exit(0)
    text = p.read_text(encoding="utf-8")
    today = datetime.date.today().isoformat()
    def repl_front(m):
        fm_raw = m.group(1)
        def patch(key, value, raw):
            pat = re.compile(rf"^{re.escape(key)}\s*:.*$", re.MULTILINE)
            replacement = f"{key}: {value}"
            if pat.search(raw):
                return pat.sub(replacement, raw)
            else:
                return raw + f"\n{replacement}"
        fm_raw = patch("status", "open", fm_raw)
        fm_raw = patch("closed", "null", fm_raw)
        fm_raw = patch("updated", today, fm_raw)
        return f"---\n{fm_raw}\n---\n"
    new_text, _ = FRONT_RE.subn(repl_front, text, count=1)
    OPEN_DIR.mkdir(parents=True, exist_ok=True)
    dest = OPEN_DIR / p.name
    if dest.exists():
        print(f"Destination {dest} exists — abort", file=sys.stderr)
        sys.exit(1)
    dest.write_text(new_text, encoding="utf-8")
    p.unlink()
    print(f"Reopened #{args.id}: {p.name} → {dest}")

def cmd_new(args):
    title = args.title.strip()
    slug = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")
    slug = re.sub(r"-{2,}", "-", slug)[:50]
    # find next id
    max_id = 0
    for d in (OPEN_DIR, CLOSED_DIR):
        for p in d.glob("*.md"):
            m = ID_RE.match(p.name)
            if m:
                try:
                    max_id = max(max_id, int(m.group(1)))
                except: pass
    next_id = f"{max_id+1:03d}"
    filename = f"{next_id}-{slug}.md"
    dest = OPEN_DIR / filename
    if not TEMPLATE.exists():
        print(f"TEMPLATE.md not found at {TEMPLATE}", file=sys.stderr)
        sys.exit(1)
    text = TEMPLATE.read_text(encoding="utf-8")
    today = datetime.date.today().isoformat()
    # patch frontmatter
    def patch(key, value, raw):
        pat = re.compile(rf"^{re.escape(key)}\s*:.*$", re.MULTILINE)
        replacement = f'{key}: "{value}"' if key in ("title",) else f"{key}: {value}"
        # special handling for labels list
        if key=="labels" and isinstance(value, str):
            pass
        if pat.search(raw):
            return pat.sub(replacement, raw)
        else:
            return raw + f"\n{replacement}"
    m = FRONT_RE.search(text)
    if m:
        fm_raw = m.group(1)
        fm_raw = re.sub(r'^id\s*:.*$', f'id: "{next_id}"', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^title\s*:.*$', f'title: "{title}"', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^status\s*:.*$', f'status: open', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^priority\s*:.*$', f'priority: {args.priority}', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^type\s*:.*$', f'type: {args.type}', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^created\s*:.*$', f'created: {today}', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^updated\s*:.*$', f'updated: {today}', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^closed\s*:.*$', f'closed: null', fm_raw, flags=re.MULTILINE)
        fm_raw = re.sub(r'^estimated_tokens\s*:.*$', f'estimated_tokens: {args.estimate}', fm_raw, flags=re.MULTILINE)
        if args.labels:
            labels_str = "[" + ", ".join(args.labels.split(",")) + "]" if "," in args.labels else f"[{args.labels}]"
            # try to keep simple
            fm_raw = re.sub(r'^labels\s*:.*$', f'labels: {args.labels if args.labels.strip().startswith("[") else "["+args.labels+"]"}', fm_raw, flags=re.MULTILINE)
        # fix first heading
        text = FRONT_RE.sub(f"---\n{fm_raw}\n---\n", text, count=1)
        text = re.sub(r'^# 000.*$', f'# {next_id} — {title}', text, flags=re.MULTILINE)
    dest.write_text(text, encoding="utf-8")
    print(f"Created {dest}  (id={next_id})")
    print(f"Next: edit frontmatter/body, then git add {dest}")

def cmd_stats(args):
    open_issues = all_issues(("open",))
    closed_issues = all_issues(("closed",))
    all_i = open_issues + closed_issues
    def count_by(key):
        d={}
        for i in all_i:
            k=str(i.get(key,"?"))
            d[k]=d.get(k,0)+1
        return d
    stats={
        "total": len(all_i),
        "open": len(open_issues),
        "closed": len(closed_issues),
        "by_priority": count_by("priority"),
        "by_type": count_by("type"),
        "by_status": count_by("status"),
        "open_ids": sorted([i["id"] for i in open_issues]),
        "closed_ids": sorted([i["id"] for i in closed_issues]),
    }
    if args.json:
        print(json.dumps(stats, indent=2))
    else:
        print(f"Total: {stats['total']}  Open: {stats['open']}  Closed: {stats['closed']}")
        print(f"By priority: {stats['by_priority']}")
        print(f"By type:     {stats['by_type']}")
        print(f"By status:   {stats['by_status']}")
        print(f"Open IDs:   {', '.join(stats['open_ids']) if stats['open_ids'] else '—'}")
        print(f"Closed IDs: {', '.join(stats['closed_ids']) if stats['closed_ids'] else '—'}")

def cmd_validate(args):
    ok=True
    seen_ids=set()
    for d in (OPEN_DIR, CLOSED_DIR):
        for p in sorted(d.glob("*.md")):
            if p.name in ("README.md",): continue
            m = ID_RE.match(p.name)
            if not m:
                if p.suffix==".md":
                    print(f"WARN: {p} does not match NNN-kebab.md")
                continue
            fid=m.group(1)
            data=parse_issue(p)
            fm=data["frontmatter"]
            # checks
            if not fm:
                print(f"FAIL: {p} — no frontmatter")
                ok=False
                continue
            if str(fm.get("id","")).zfill(3) != fid:
                print(f"FAIL: {p} — id {fm.get('id')} != filename {fid}")
                ok=False
            if fid in seen_ids:
                print(f"FAIL: duplicate id {fid} at {p}")
                ok=False
            seen_ids.add(fid)
            for k in ("title","status","priority","type","created","updated"):
                if k not in fm:
                    print(f"FAIL: {p} — missing frontmatter key {k}")
                    ok=False
            if d==OPEN_DIR and fm.get("status")=="closed":
                print(f"FAIL: {p} in open/ but status=closed")
                ok=False
            if d==CLOSED_DIR and fm.get("status")!="closed":
                print(f"WARN: {p} in closed/ but status={fm.get('status')}")
            # priority check
            if fm.get("priority") not in ("P1","P2","P3","P4"):
                print(f"WARN: {p} — unexpected priority {fm.get('priority')}")
            if fm.get("type") not in ("feature","bug","chore","docs","test","research"):
                print(f"WARN: {p} — unexpected type {fm.get('type')}")
            # date check
            for dk in ("created","updated"):
                v=fm.get(dk)
                if v and v!="null":
                    try:
                        datetime.date.fromisoformat(str(v))
                    except:
                        print(f"WARN: {p} — bad date {dk}={v}")
    if ok:
        print("validate: OK — all issues pass naming + frontmatter checks")
    else:
        print("validate: FAILED — see above", file=sys.stderr)
        sys.exit(1)

def main():
    ap=argparse.ArgumentParser(description="Localized issues helper")
    sub=ap.add_subparsers(dest="cmd", required=True)
    # list
    p_list=sub.add_parser("list", help="list issues")
    p_list.add_argument("--all", action="store_true", help="open+closed")
    p_list.add_argument("--open", action="store_true", help="only open (default)")
    p_list.add_argument("--closed", action="store_true", help="only closed")
    p_list.add_argument("--json", action="store_true")
    p_list.set_defaults(func=cmd_list)
    # show
    p_show=sub.add_parser("show", help="show issue")
    p_show.add_argument("id", help="NNN e.g. 001")
    p_show.set_defaults(func=cmd_show)
    # close
    p_close=sub.add_parser("close", help="close issue (mv open→closed)")
    p_close.add_argument("id", help="NNN")
    p_close.add_argument("--reason", default="", help="resolution note")
    p_close.set_defaults(func=cmd_close)
    # reopen
    p_reopen=sub.add_parser("reopen", help="reopen issue (mv closed→open)")
    p_reopen.add_argument("id", help="NNN")
    p_reopen.set_defaults(func=cmd_reopen)
    # new
    p_new=sub.add_parser("new", help="create new issue from template")
    p_new.add_argument("title", help="issue title")
    p_new.add_argument("--priority", default="P2", choices=["P1","P2","P3","P4"])
    p_new.add_argument("--type", dest="type", default="feature", choices=["feature","bug","chore","docs","test","research"])
    p_new.add_argument("--estimate", default="20000", help="estimated tokens")
    p_new.add_argument("--labels", default="", help="comma separated")
    p_new.set_defaults(func=cmd_new)
    # stats
    p_stats=sub.add_parser("stats", help="counts")
    p_stats.add_argument("--json", action="store_true")
    p_stats.set_defaults(func=cmd_stats)
    # validate
    p_val=sub.add_parser("validate", help="lint issues")
    p_val.set_defaults(func=cmd_validate)

    args=ap.parse_args()
    # ensure dirs exist
    OPEN_DIR.mkdir(parents=True, exist_ok=True)
    CLOSED_DIR.mkdir(parents=True, exist_ok=True)
    args.func(args)

if __name__=="__main__":
    main()
