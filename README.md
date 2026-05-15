# claude-thermal-optimizer

macOS thermal management for AI workloads: cache clearing, process prioritization, Ollama watchdog, and CPU throttle prevention.

![macOS](https://img.shields.io/badge/macOS-Monterey+-blue?style=flat&labelColor=555) ![Thermal](https://img.shields.io/badge/Thermal-Optimized-green?style=flat&labelColor=555) ![Ollama](https://img.shields.io/badge/Ollama-Watchdog-orange?style=flat&labelColor=555) ![License](https://img.shields.io/badge/License-MIT-yellow?style=flat&labelColor=555)

[Concepts](#-concepts) · [How It Works](#-how-it-works) · [Install](#-install) · [Usage](#-usage) · [Config](#-configuration) · [Tips](#-tips-and-tricks-12) · [Troubleshooting](#-troubleshooting) · [Architecture](#-architecture) · [Startups](#️-startups--businesses)

---

## 🧠 CONCEPTS

| Feature | Location | Description |
|---|---|---|
| Cache Cleaner | `scripts/clear_cache.sh` | Clears system cache, Xcode DerivedData, npm/pip caches |
| Process Prioritizer | `scripts/nice_processes.sh` | Renice heavy background processes to free CPU for AI |
| Ollama Watchdog | `scripts/ollama_watchdog.py` | Ensures Ollama stays running — restarts if crashed |
| Thermal Monitor | `scripts/thermal_monitor.py` | Polls CPU temp, logs anomalies, alerts on sustained high temps |
| Memory Pressure Relief | `scripts/memory_relief.sh` | Purges inactive memory when pressure exceeds threshold |
| GPU Load Balancer | `scripts/gpu_balance.sh` | Routes Ollama inference to GPU vs CPU based on thermal state |
| LaunchAgent Templates | `launchagents/` | Ready-to-install plist files for all watchdog scripts |
| Disk Cleanup | `scripts/disk_cleanup.sh` | Removes logs, caches, and temp files eating SSD space |
| CPU Burst Mode | `scripts/cpu_burst.sh` | Temporarily boosts performance for intensive inference tasks |
| Health Dashboard | `ui/dashboard.py` | Terminal dashboard: temp, memory, CPU, Ollama status |
| Alert Config | `config/alerts.yaml` | Thresholds for CPU temp, memory pressure, disk usage |
| Battery Optimizer | `scripts/battery_optimize.sh` | Throttles background AI tasks when on battery |

### 🔥 Hot

| Feature | Location | Description |
|---|---|---|
| Ollama Watchdog | `scripts/ollama_watchdog.py` | Ollama must NEVER die — watchdog restarts in <30s |
| Thermal Monitor | `scripts/thermal_monitor.py` | Catches thermal throttling before it slows inference |
| Memory Relief | `scripts/memory_relief.sh` | LLM inference needs clean RAM — purges inactive pages |
| Health Dashboard | `ui/dashboard.py` | Live terminal view: all system metrics at a glance |
| LaunchAgents | `launchagents/` | Install once — all watchdogs auto-start on boot |

---

## ⚙️ HOW IT WORKS

```
macOS Boot
    │
    └── LaunchAgents load:
        ├── ollama_watchdog.py    (60s poll)
        ├── thermal_monitor.py   (30s poll)
        └── memory_relief.sh     (5min poll)

During AI Workload:
    CPU Temp > 85°C
        └── thermal_monitor.py
            ├── log to thermal_log.jsonl
            ├── send alert if sustained >2min
            └── trigger memory_relief.sh

    Ollama crash detected
        └── ollama_watchdog.py
            ├── restart: `ollama serve`
            └── verify: health check endpoint

    Memory pressure > 80%
        └── memory_relief.sh
            └── purge inactive pages
```

---

## 🚀 INSTALL

```bash
git clone https://github.com/hmzainjamil/claude-thermal-optimizer
cd claude-thermal-optimizer

# Python deps
pip install psutil requests rich

# Install all LaunchAgents
bash scripts/install_launchagents.sh

# Verify installation
launchctl list | grep thermal

# Check current system health
python3 ui/dashboard.py

# Manual thermal relief
bash scripts/clear_cache.sh
bash scripts/memory_relief.sh
```

---

## 📟 USAGE

```bash
# Live health dashboard
python3 ui/dashboard.py

# Manual cache clear
bash scripts/clear_cache.sh

# Check Ollama status
python3 scripts/ollama_watchdog.py --status

# Force memory purge
bash scripts/memory_relief.sh --force

# Renice background processes
bash scripts/nice_processes.sh

# View thermal log
python3 scripts/thermal_monitor.py --log-view --last 100

# Check disk usage
bash scripts/disk_cleanup.sh --dry-run

# Run full optimization
bash scripts/optimize_all.sh
```

---

## ⚙️ CONFIGURATION

| Variable | Default | Description |
|---|---|---|
| `THERMAL_ALERT_TEMP_C` | `88` | CPU temp alert threshold (Celsius) |
| `THERMAL_SUSTAINED_SECONDS` | `120` | Seconds above threshold before alert |
| `MEMORY_PRESSURE_THRESHOLD` | `0.80` | Memory pressure ratio to trigger relief |
| `OLLAMA_HEALTH_URL` | `http://localhost:11434` | Ollama health check endpoint |
| `OLLAMA_RESTART_DELAY_S` | `5` | Seconds to wait before restarting Ollama |
| `WATCHDOG_POLL_INTERVAL_S` | `60` | How often watchdog checks Ollama |
| `DISK_WARN_GB_FREE` | `20` | Alert when disk free space below this |
| `CACHE_CLEAN_INTERVAL_HOURS` | `24` | Auto cache clean interval |
| `BATTERY_THROTTLE_ENABLED` | `true` | Throttle AI tasks on battery |
| `LOG_DIR` | `~/.thermal-optimizer/logs/` | Log directory |

---

## 💡 TIPS AND TRICKS (12)

[Thermal](#tips-thermal) · [Ollama](#tips-ollama) · [Memory](#tips-memory) · [Automation](#tips-auto)

<a id="tips-thermal"></a>■ **Thermal Management (3)**

| Tip | Source |
|---|---|
| Run Ollama inference at `nice 10` — prevents it from competing with system tasks | nice_processes.sh |
| Sustained 90°C+ causes CPU throttle — thermal log helps diagnose inference slowdowns | Thermal monitor |
| macOS `sysctl -n machdep.xcpm.cpu_thermal_level` shows throttle level (0=none) | macOS sysctl |

<a id="tips-ollama"></a>■ **Ollama Stability (3)**

| Tip | Source |
|---|---|
| Ollama must NEVER be stopped — watchdog ensures this even on OOM kills | Watchdog design |
| `OLLAMA_NUM_PARALLEL=1` prevents memory exhaustion on 16GB Macs | Ollama env vars |
| `OLLAMA_KEEP_ALIVE=60m` keeps models loaded — avoids cold-start latency | Ollama docs |

<a id="tips-memory"></a>■ **Memory Optimization (3)**

| Tip | Source |
|---|---|
| `sudo purge` clears inactive memory — run before large inference tasks | macOS docs |
| LLM model loading needs ~2× model size in RAM — check free before pulling 70B | Ollama memory guide |
| Close Chrome before inference — browser eats 4-8GB RAM on typical setups | System profiling |

<a id="tips-auto"></a>■ **Automation (3)**

| Tip | Source |
|---|---|
| LaunchAgents survive reboots — install once, forget it | macOS LaunchAgent docs |
| `battery_optimize.sh` protects MacBook battery health during long inference sessions | Battery guide |
| Dashboard runs in tmux — keep it open in a corner for passive monitoring | Terminal tips |

---

## 🔧 TROUBLESHOOTING

| Issue | Fix |
|---|---|
| Ollama keeps dying | Check `OLLAMA_NUM_PARALLEL` — reduce to 1 if OOM |
| Watchdog not auto-starting | `launchctl load ~/Library/LaunchAgents/com.hmz.ollama-watchdog.plist` |
| CPU always throttling | Check `Activity Monitor` → Energy — find CPU hog |
| Memory pressure won't clear | `sudo purge` in terminal — stronger than script |
| Dashboard shows wrong temp | Install `osx-cpu-temp`: `brew install osx-cpu-temp` |
| LaunchAgent fails silently | Check: `cat ~/Library/Logs/thermal-optimizer.log` |
| Disk cleanup too aggressive | Use `--dry-run` first to preview deletions |

---

## 📊 ARCHITECTURE

```
claude-thermal-optimizer/
├── scripts/
│   ├── ollama_watchdog.py      # Ollama restart guardian
│   ├── thermal_monitor.py      # CPU temp monitoring
│   ├── memory_relief.sh        # Memory pressure relief
│   ├── clear_cache.sh          # System cache clearing
│   ├── nice_processes.sh       # Process priority tuning
│   ├── gpu_balance.sh          # GPU/CPU routing
│   ├── disk_cleanup.sh         # Disk space recovery
│   ├── cpu_burst.sh            # Temporary boost mode
│   ├── battery_optimize.sh     # Battery-aware throttling
│   ├── optimize_all.sh         # Full optimization run
│   └── install_launchagents.sh # One-command install
├── launchagents/
│   ├── com.hmz.ollama-watchdog.plist
│   ├── com.hmz.thermal-monitor.plist
│   └── com.hmz.memory-relief.plist
├── config/
│   └── alerts.yaml             # Threshold configuration
├── ui/
│   └── dashboard.py            # Terminal health dashboard
├── logs/                       # Thermal and event logs
└── requirements.txt
```

---

## ☠️ STARTUPS / BUSINESSES

| This Repo / Feature | Replaced |
|---|---|
| Ollama Watchdog | Inference dying mid-session, no auto-recovery |
| Thermal Monitor | Unknown CPU throttling causing slow responses |
| Memory Relief | LLM OOM kills from browser + Ollama competing |
| Cache Cleaner | Manual monthly disk cleanup |
| LaunchAgents | Manual restart of watchdog scripts after reboot |
| Battery Optimizer | Battery drain from constant AI inference |
| Health Dashboard | No visibility into why system felt slow |
| Disk Cleanup | Xcode/npm caches eating 50GB without notice |

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=hmzainjamil/claude-thermal-optimizer&type=Date)](https://star-history.com/#hmzainjamil/claude-thermal-optimizer&Date)

---
<div align="center">Built by <a href="https://github.com/hmzainjamil">HMZ</a> · Part of HMZ Claude AI System</div>

---

## 🔄 CONTRIBUTING

PRs welcome. Please:
1. Fork the repo
2. Create a feature branch
3. Add tests for new functionality
4. Submit PR with description of changes

---

## 📊 THERMAL EVENT LOG FORMAT

```jsonl
{"ts": "2025-01-15T09:32:11", "cpu_temp_c": 91, "memory_pressure": 0.72, "event": "thermal_alert", "action": "memory_relief_triggered"}
{"ts": "2025-01-15T09:45:00", "cpu_temp_c": 78, "memory_pressure": 0.55, "event": "normal", "action": null}
{"ts": "2025-01-15T10:00:00", "ollama_status": "crashed", "event": "watchdog_restart", "action": "ollama_restarted"}
```

---

## 🖥️ HEALTH DASHBOARD OUTPUT

```
┌─────────────────────────────────────────┐
│  SYSTEM HEALTH — 2025-01-15 10:30:00    │
├─────────────────────────────────────────┤
│  CPU Temp:      76°C   [████████░░] OK  │
│  Memory:        68%    [███████░░░] OK  │
│  Disk Free:     145 GB [████░░░░░░] OK  │
│  Ollama:        RUNNING on :11434       │
│  Active Model:  llama3.1:8b (loaded)    │
│  GPU Layers:    32/32  [METAL]          │
│  Inference:     ~45 tok/s               │
└─────────────────────────────────────────┘
```

---

## ⚙️ LAUNCHAGENT PLIST TEMPLATE

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN">
<plist version="1.0">
<dict>
  <key>Label</key><string>com.hmz.ollama-watchdog</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>/path/to/ollama_watchdog.py</string>
  </array>
  <key>StartInterval</key><integer>60</integer>
  <key>RunAtLoad</key><true/>
</dict>
</plist>
```
