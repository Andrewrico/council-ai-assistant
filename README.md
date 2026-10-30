# Council — Roger (the harness council)

A small, plain-shell dispatcher for an ensemble AI operator. `council` takes a task,
prepends the operator identity in `IDENTITY.md`, runs it on any CLI that has a `-p <prompt>`
mode, and writes a run log. No Node, no daemon, no hosted service. bash 3.2+ (macOS and Linux).

## Install

```
git clone https://github.com/Andrewrico/council-ai-assistant
cd council-ai-assistant
./install.sh                    # symlinks bin/council into ~/.local/bin
export COUNCIL_ENGINE_CLI=<your-engine-cli>   # any CLI with a -p prompt mode
council --help
```

`./install.sh /other/dir` links elsewhere, `./install.sh --uninstall` removes the link.
You can also run `bin/council` directly.

## Use

```
council "Cross-check this plan and execute the safe parts"
council --advisory "Which executor should take this task?"   # read-only run
council --file task.md
echo "long task" | council
council --no-exec "dry run"      # build the task and write the log, don't run the engine
```

Exit code is the engine's. Every run writes `runs/<timestamp>-<slug>.log`.

## Configuration

| Variable | Meaning |
| --- | --- |
| `COUNCIL_ENGINE_CLI` | **Required.** Engine command with a `-p <prompt>` mode |
| `COUNCIL_MODEL` | Passed as `--model` (or use `-m`) |
| `COUNCIL_ENV_UNSET` | Space-separated env vars to drop before the run (e.g. API keys) |
| `COUNCIL_EXEC_ARGS` | Extra engine args in execute mode (default: `--allowedTools Read,Grep,Glob,Bash,Write,Edit --permission-mode acceptEdits`) |
| `COUNCIL_ADVISORY_ARGS` | Extra engine args for `--advisory` (default: `--allowedTools Read,Grep,Glob`) |
| `COUNCIL_PREAMBLE_FILE` | Optional file of house rules prepended before the identity |
| `COUNCIL_WORKSPACE` | Directory the engine runs in (default: current directory) |
| `COUNCIL_HOME` | Where `IDENTITY.md` lives (default: this checkout) |
| `COUNCIL_RUNS_DIR` | Run logs (default: `$COUNCIL_HOME/runs`) |

The default tool flags suit engines that accept `--allowedTools` and `--permission-mode`.
For others, set `COUNCIL_EXEC_ARGS` / `COUNCIL_ADVISORY_ARGS` (an empty value passes nothing).
**Execute mode lets the engine write files and run commands in `COUNCIL_WORKSPACE`.**
Use `--advisory` for read-only work.

## Layout

| Path | Purpose |
| --- | --- |
| `bin/council` | the dispatcher (shell script) |
| `install.sh` | symlink installer |
| `IDENTITY.md` | operator identity, injected into every run |
| `CONSTITUTION.md` | the rules every run follows |
| `skills-council/` | nine short working principles, one per `SKILL.md` |
| `cli-config.json` | descriptive metadata (not read by the script) |
| `tests/test.sh` | test suite (uses a fake engine) |
| `runs/` | run logs (git-ignored) |

## Test

```
bash tests/test.sh
```

## License

MIT, see [LICENSE](LICENSE).
