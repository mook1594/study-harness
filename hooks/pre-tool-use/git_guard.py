#!/usr/bin/env python3
import json, sys, re, os, datetime, subprocess

LOG_PATH = ".claude/.local/hooks.log"

def log(msg: str) -> None:
    try:
        os.makedirs(os.path.dirname(LOG_PATH), exist_ok=True)
        ts = datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ")
        with open(LOG_PATH, "a", encoding="utf-8") as f:
            f.write(f"[git_guard] {ts} {msg}\n")
    except Exception:
        pass

HARD_DENY = [
    re.compile(r"\bgit\s+push\b.*\s--force\b"),
    re.compile(r"\bgit\s+push\b.*\s-f\b"),
    re.compile(r"\bgit\s+reset\b.*\s--hard\b"),
    re.compile(r"\bgit\s+clean\b.*\s-f\b"),
    re.compile(r"\bgit\s+clean\b.*\s-d\b"),
]
ASK = [
    re.compile(r"\bgit\s+rebase\b"),
    re.compile(r"\bgit\s+checkout\b\s+(-b\s+)?main\b"),
    re.compile(r"\bgit\s+merge\b"),
]

def main():
    data = json.load(sys.stdin)
    tool_input = data.get("tool_input", {}) or {}
    cmd = tool_input.get("command", "") or ""

    log(f"cmd={cmd!r}")

    # git 관련 명령 아니면 통과
    if "git " not in cmd:
        log("decision=allow reason=not_git_command")
        print(json.dumps({"hookSpecificOutput":{
            "hookEventName":"PreToolUse",
            "permissionDecision":"allow",
            "permissionDecisionReason":"Not a git command"
        }}))
        return

    for pat in HARD_DENY:
        if pat.search(cmd):
            log("decision=deny reason=risky_git_command")
            print(json.dumps({"hookSpecificOutput":{
                "hookEventName":"PreToolUse",
                "permissionDecision":"deny",
                "permissionDecisionReason":f"Blocked risky git command: {cmd}"
            }}))
            return

    for pat in ASK:
        if pat.search(cmd):
            log("decision=ask reason=potentially_risky_git_operation")
            print(json.dumps({"hookSpecificOutput":{
                "hookEventName":"PreToolUse",
                "permissionDecision":"ask",
                "permissionDecisionReason":f"Potentially risky git operation. Confirm: {cmd}",
                "updatedInput":{"command": cmd}
            }}))
            return

    # main/master에서 git commit 시도 시 feature 브랜치 생성 요청
    # chained 명령(git checkout -b ... && git commit)은 허용
    has_checkout_new_branch = bool(re.search(r"\bgit\s+checkout\s+-b\b", cmd))
    if re.search(r"\bgit\s+commit\b", cmd) and not has_checkout_new_branch:
        try:
            branch = subprocess.check_output(
                ["git", "branch", "--show-current"],
                text=True, stderr=subprocess.DEVNULL
            ).strip()
            if branch in ("main", "master"):
                ts = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
                new_branch = f"feature/{ts}"
                log(f"decision=deny reason=commit_on_main suggested_branch={new_branch}")
                print(json.dumps({"hookSpecificOutput":{
                    "hookEventName":"PreToolUse",
                    "permissionDecision":"deny",
                    "permissionDecisionReason":(
                        f"main 브랜치에 직접 커밋할 수 없습니다. "
                        f"먼저 'git checkout -b {new_branch}' 를 실행하고 커밋하세요."
                    )
                }}))
                return
        except Exception:
            pass

    log("decision=allow reason=ok")
    print(json.dumps({"hookSpecificOutput":{
        "hookEventName":"PreToolUse",
        "permissionDecision":"allow",
        "permissionDecisionReason":"OK"
    }}))

if __name__ == "__main__":
    main()
