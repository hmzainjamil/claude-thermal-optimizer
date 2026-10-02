# Claude and Ollama Watchdog

A small macOS shell watchdog that polls aggregate CPU use from processes whose names match Claude, then runs `ollama stop` for two hard-coded model names after a configured idle interval. It does not read thermal sensors, clear caches, throttle processes, or restart Ollama models.

## Repository map

| Path | Purpose |
|---|---|
| `ollama-claude-watchdog.sh` | Infinite polling loop, process CPU check, model-stop command, and log output |
| `com.claude.ollama-watchdog.plist` | launchd job example with machine-specific script and log paths |
| `README.md` | Usage, behavior, and limitations |

## What the script does

The script samples every 10 seconds. It sums CPU percentages for matching Claude-named processes. When the sum remains below 5 for 30 seconds, it runs:

- `/usr/local/bin/ollama stop qwen2.5:7b`
- `/usr/local/bin/ollama stop llama3:latest`

The paths, model names, thresholds, interval, and log path are hard-coded in the script. Its `resume_ollama` function only changes an internal flag and logs that Claude is active; it does not run `ollama start`. “Idle” is inferred from process CPU use, not from Claude's task state or hardware temperature.

## launchd configuration

The checked-in plist runs at load and uses `KeepAlive`. It references `/Users/mc/.claude/bin/ollama-claude-watchdog.sh`, while the repository stores the script at its root. It also writes logs under `/tmp`. These machine-specific paths must be reviewed and corrected for the target machine before the plist is loaded. The repository does not include an installer or validated service management procedure.

## Safety and limitations

- Running the watchdog continuously can stop the named Ollama models after the idle threshold.
- The CPU process-name match may include multiple Claude processes and does not establish whether a user is actively working.
- No temperature reading or thermal-management action is implemented.
- No restart occurs when Claude becomes active.
- The watchdog writes timestamped events to `/tmp/ollama-watchdog.log`; the plist separately routes stdout and stderr under `/tmp`.
- Review the script and paths before running or loading it. No run/install commands are provided because the checked-in launchd paths are host-specific and the resume behavior is incomplete.

## Validation and release status

The behavior above is documented from the checked-in shell script and plist; neither was executed or loaded during this review. There is no test suite or license file, and GitHub metadata reports no declared license. Do not infer permission to reuse or redistribute the files.

## Maintainer

[hmzainjamil](https://github.com/hmzainjamil)
