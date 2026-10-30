#!/usr/bin/env bash
# Test suite for bin/council and install.sh. Uses a fake engine; no network, no real model.
set -u
ROOT="$(cd -P "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
T="$(mktemp -d)"; trap 'rm -rf "$T"' EXIT
PASS=0; FAIL=0
ok()   { PASS=$((PASS+1)); echo "ok   - $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL - $1"; }
check(){ if eval "$2"; then ok "$1"; else bad "$1"; fi; }

# Fake engine: prints its args (first 2 = -p <prompt>, rest shown), cwd, a secret var, exit code from FAKE_RC.
cat > "$T/fake" <<'FAKE'
#!/bin/bash
prompt="$2"; shift 2
echo "REST: $*"
echo "PWD: $PWD"
echo "KEY: ${FAKE_KEY:-unset}"
case "$prompt" in *"IDENTITY"*) echo "IDENTITY: yes" ;; *) echo "IDENTITY: no" ;; esac
case "$prompt" in *"HOUSE-RULES"*) echo "PREAMBLE: yes" ;; esac
echo "TASKEND: ${prompt##*---}"
exit "${FAKE_RC:-0}"
FAKE
chmod +x "$T/fake"
export COUNCIL_RUNS_DIR="$T/runs"
C="$ROOT/bin/council"

check "syntax: bin/council"  'bash -n "$C"'
check "syntax: install.sh"   'bash -n "$ROOT/install.sh"'

out="$("$C" --help 2>&1)"
check "--help prints usage" '[[ "$out" == *"Usage:"* ]]'

out="$("$C" </dev/null 2>&1)"; rc=$?
check "no task: exit 1" '[ $rc -eq 1 ]'

out="$(COUNCIL_ENGINE_CLI= "$C" hi 2>&1)"; rc=$?
check "no engine: exit 127" '[ $rc -eq 127 ]'
out="$(COUNCIL_ENGINE_CLI=nope-not-here "$C" hi 2>&1)"; rc=$?
check "missing engine binary: exit 127" '[ $rc -eq 127 ]'

out="$("$C" --model 2>&1)"; rc=$?
check "--model without value: exit 1" '[ $rc -eq 1 ]'

out="$(COUNCIL_ENGINE_CLI="$T/fake" COUNCIL_WORKSPACE="$T" COUNCIL_MODEL=m1 "$C" "do the thing" 2>/dev/null)"; rc=$?
check "execute: exit 0"                  '[ $rc -eq 0 ]'
check "execute: identity injected"       '[[ "$out" == *"IDENTITY: yes"* ]]'
check "execute: task appended"           '[[ "$out" == *"do the thing"* ]]'
check "execute: model flag passed"       '[[ "$out" == *"--model m1"* ]]'
check "execute: default exec args"       '[[ "$out" == *"--allowedTools Read,Grep,Glob,Bash,Write,Edit --permission-mode acceptEdits"* ]]'
check "execute: runs in workspace"       '[[ "$out" == *"PWD: $T"* || "$out" == *"PWD: /private$T"* ]]'
check "execute: run log written"         'ls "$T"/runs/*do-the-thing.log >/dev/null 2>&1'

out="$(COUNCIL_ENGINE_CLI="$T/fake" "$C" --advisory poll 2>/dev/null)"
check "advisory: read-only args"         '[[ "$out" == *"--allowedTools Read,Grep,Glob"* && "$out" != *"Bash"* ]]'

out="$(COUNCIL_ENGINE_CLI="$T/fake" COUNCIL_EXEC_ARGS= "$C" x 2>/dev/null)"
check "empty COUNCIL_EXEC_ARGS passes nothing" '[[ "$out" == *"REST: "$'"'"'\n'"'"'* || "$out" == "REST: "* ]]'

out="$(COUNCIL_ENGINE_CLI="$T/fake" COUNCIL_EXEC_ARGS="--foo bar" "$C" x 2>/dev/null)"
check "custom COUNCIL_EXEC_ARGS used"   '[[ "$out" == *"REST: --foo bar"* ]]'

out="$(FAKE_KEY=abc COUNCIL_ENV_UNSET="FAKE_KEY" COUNCIL_ENGINE_CLI="$T/fake" "$C" x 2>/dev/null)"
check "COUNCIL_ENV_UNSET drops the var" '[[ "$out" == *"KEY: unset"* ]]'
out="$(FAKE_KEY=abc COUNCIL_ENGINE_CLI="$T/fake" "$C" x 2>/dev/null)"
check "env var kept when not listed"    '[[ "$out" == *"KEY: abc"* ]]'

echo "HOUSE-RULES" > "$T/pre.md"
out="$(COUNCIL_PREAMBLE_FILE="$T/pre.md" COUNCIL_ENGINE_CLI="$T/fake" "$C" x 2>/dev/null)"
check "preamble file injected"          '[[ "$out" == *"PREAMBLE: yes"* ]]'
out="$(COUNCIL_PREAMBLE_FILE="$T/nope" COUNCIL_ENGINE_CLI="$T/fake" "$C" x 2>&1)"; rc=$?
check "unreadable preamble: exit 1"     '[ $rc -eq 1 ]'

out="$(echo "from stdin" | COUNCIL_ENGINE_CLI="$T/fake" "$C" 2>/dev/null)"
check "task from stdin"                 '[[ "$out" == *"from stdin"* ]]'
echo "from file" > "$T/task.md"
out="$(COUNCIL_ENGINE_CLI="$T/fake" "$C" --file "$T/task.md" 2>/dev/null)"
check "task from --file"                '[[ "$out" == *"from file"* ]]'
out="$(COUNCIL_ENGINE_CLI="$T/fake" "$C" --file "$T/missing" 2>&1)"; rc=$?
check "missing --file: exit 1"          '[ $rc -eq 1 ]'

FAKE_RC=3 COUNCIL_ENGINE_CLI="$T/fake" "$C" x >/dev/null 2>&1; rc=$?
check "engine exit code passed through" '[ $rc -eq 3 ]'

out="$("$C" --no-exec dry 2>&1)"; rc=$?
check "--no-exec works without engine"  '[ $rc -eq 0 ] && [[ "$out" == *"engine not run"* ]]'

# Multi-word, quote and special-char task survives intact.
out="$(COUNCIL_ENGINE_CLI="$T/fake" "$C" 'say "hi" & $HOME `date`' 2>/dev/null)"
check "special characters preserved"    '[[ "$out" == *'"'"'say "hi" & $HOME `date`'"'"'* ]]'

# Symlink install resolves COUNCIL_HOME through the link (identity still found).
mkdir -p "$T/bin"
"$ROOT/install.sh" "$T/bin" >/dev/null 2>&1
check "install: link created"           '[ -L "$T/bin/council" ]'
out="$(COUNCIL_ENGINE_CLI="$T/fake" "$T/bin/council" x 2>/dev/null)"
check "installed link finds IDENTITY.md" '[[ "$out" == *"IDENTITY: yes"* ]]'
"$ROOT/install.sh" --uninstall "$T/bin" >/dev/null 2>&1
check "uninstall: link removed"         '[ ! -e "$T/bin/council" ]'
echo "not ours" > "$T/bin/council"
"$ROOT/install.sh" "$T/bin" >/dev/null 2>&1; rc=$?
check "install refuses to overwrite a real file" '[ $rc -ne 0 ] && grep -q "not ours" "$T/bin/council"'

check "cli-config.json is valid JSON"   'python3 -c "import json,sys;json.load(open(sys.argv[1]))" "$ROOT/cli-config.json" || ! command -v python3 >/dev/null'
check "LICENSE present"                 '[ -s "$ROOT/LICENSE" ]'
check "9 skills have SKILL.md"          '[ "$(ls "$ROOT"/skills-council/*/SKILL.md | wc -l | tr -d " ")" = 9 ]'
check "no internal host refs in repo"   '! grep -rniE "/root|mission-control|WORKER_SECRET|mc-protocol" "$ROOT" --exclude-dir=.git --exclude-dir=tests --exclude-dir=runs'

echo; echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
