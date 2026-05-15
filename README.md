# claude-thermal-optimizer
Auto-pause Ollama when Claude is idle — zero-config thermal management for macOS power users

![macOS](https://img.shields.io/badge/macOS-Apple_Silicon-black?style=flat&labelColor=555&logo=apple)
![Shell](https://img.shields.io/badge/Shell-Bash-4EAA25?style=flat&labelColor=555&logo=gnubash)
![Claude](https://img.shields.io/badge/Claude-Code-cc785c?style=flat&labelColor=555)
![Ollama](https://img.shields.io/badge/Ollama-Auto_Pause-white?style=flat&labelColor=555)
![License](https://img.shields.io/badge/License-MIT-blue?style=flat&labelColor=555)
![Status](https://img.shields.io/badge/Status-Active-brightgreen?style=flat&labelColor=555)

[Concepts](#-concepts) · [How It Works](#-how-it-works) · [Install](#-install) · [Tips](#-tips-and-tricks-8) · [Config](#-configuration) · [Startups](#-startups--businesses)

---

## 🧠 CONCEPTS

| Feature | Location | Description |
|---------|----------|-------------|
| [**Ollama Watchdog**](ollama-claude-watchdog.sh) | `ollama-claude-watchdog.sh` | Monitors Claude CPU every 10s — pauses Ollama after 30s idle |
| [**LaunchAgent**](com.claude.ollama-watchdog.plist) | `com.claude.ollama-watchdog.plist` | macOS daemon — auto-starts on login, keeps watchdog alive |
| [**CPU Threshold**](ollama-claude-watchdog.sh#L8) | `IDLE_THRESHOLD=5` | Claude below 5% CPU = idle signal |
| [**Grace Period**](ollama-claude-watchdog.sh#L10) | `IDLE_GRACE=30` | 30s idle before Ollama models unloaded |
| [**Live Log**](/tmp/ollama-watchdog.log) | `/tmp/ollama-watchdog.log` | Real-time pause/resume audit trail |
| [**Multi-model**](ollama-claude-watchdog.sh#L28) | `qwen2.5:7b + llama3` | Stops all loaded models, not just one |

### 🔥 Hot

| Feature | Location | Description |
|---------|----------|-------------|
| [**Zero Manual Steps**](ollama-claude-watchdog.sh) | `LaunchAgent` | Loads at login, runs forever, self-heals via `KeepAlive` |
| [**14% CPU Recovery**](ollama-claude-watchdog.sh) | `ollama stop` | Reclaims ~14% CPU + GPU memory when Claude idles |
| [**Thermal Guard**](ollama-claude-watchdog.sh) | `watchdog loop` | Designed specifically for Mac thermal throttle prevention |

---

## ⚙️ HOW IT WORKS

```
Claude Active (CPU > 5%)  →  Ollama stays loaded  →  instant model responses
        ↓ 30s idle
Claude Idle (CPU < 5%)   →  ollama stop [models]  →  14% CPU freed
        ↓ Claude wakes
Claude Active again       →  Ollama unpaused       →  loads on next call
```

**Why this matters:**
- Ollama idles at ~14% CPU even when not serving requests
- On Apple Silicon, idle GPU load = thermal throttle = slower Claude
- This daemon eliminates the waste automatically

---

## 🚀 INSTALL

### 1. Clone
```bash
git clone https://github.com/hmzainjamil/claude-thermal-optimizer
cd claude-thermal-optimizer
```

### 2. Install watchdog
```bash
cp ollama-claude-watchdog.sh ~/.claude/bin/
chmod +x ~/.claude/bin/ollama-claude-watchdog.sh
```

### 3. Install LaunchAgent
```bash
cp com.claude.ollama-watchdog.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.claude.ollama-watchdog.plist
```

### 4. Verify
```bash
tail -f /tmp/ollama-watchdog.log
```

Expected output:
```
Thu May 15 20:19:34 PKT 2026 Watchdog started
20:20:04 PAUSED (Claude idle 30s)
20:21:17 RESUMED (Claude active)
```

---

## ⚙️ CONFIGURATION

Edit `~/.claude/bin/ollama-claude-watchdog.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `IDLE_THRESHOLD` | `5` | CPU% below which Claude = idle |
| `CHECK_INTERVAL` | `10` | Seconds between checks |
| `IDLE_GRACE` | `30` | Seconds idle before pause |

Add your models to the `pause_ollama()` function:
```bash
/usr/local/bin/ollama stop your-model-name 2>/dev/null
```

---

## 💡 TIPS AND TRICKS (8)

[thermal](#tips-thermal) · [ollama](#tips-ollama) · [macos](#tips-macos) · [claude](#tips-claude)

<a id="tips-thermal"></a>■ **Thermal Management (3)**

| Tip | Source |
|-----|--------|
| Kill `assistantd` + `triald_system` + `modelmanagerd` to save ~60% CPU — they respawn harmlessly | [HMZ](https://github.com/hmzainjamil) |
| Disable transparency: `defaults write com.apple.universalaccess reduceTransparency -bool true` — reduces WindowServer load | [Apple HIG](https://developer.apple.com/design/human-interface-guidelines/) |
| `sudo purge` clears inactive RAM pages — run when memory pressure is high | [HMZ](https://github.com/hmzainjamil) |

<a id="tips-ollama"></a>■ **Ollama (2)**

| Tip | Source |
|-----|--------|
| `ollama stop model-name` unloads model from VRAM — faster than killing the process | [Ollama Docs](https://ollama.ai/docs) |
| Models reload on next `ollama run` call — no need to pre-warm manually | [Ollama Docs](https://ollama.ai/docs) |

<a id="tips-macos"></a>■ **macOS Cleanup (2)**

| Tip | Source |
|-----|--------|
| `brew cleanup --prune=all` + `npm cache clean --force` + `sudo purge` = full cache clear | [HMZ](https://github.com/hmzainjamil) |
| Avast SystemExtension cannot be killed without SIP disable — pause shields in-app instead | [HMZ](https://github.com/hmzainjamil) |

<a id="tips-claude"></a>■ **Claude Code (1)**

| Tip | Source |
|-----|--------|
| Claude.app runs 3+ processes — total CPU is sum of all `Claude` entries in `ps aux` | [DigiMinds](https://github.com/hmzainjamil) |

---

## ☠️ STARTUPS / BUSINESSES

| This Repo / Feature | Replaced |
|-|-|
| **Ollama Watchdog** | [Raycast AI](https://raycast.com), [Alfred](https://alfred.app), manual `ollama stop` scripts |
| **LaunchAgent thermal daemon** | [Macs Fan Control](https://crystalidea.com/macs-fan-control), [TG Pro](https://www.tunabellysoftware.com/tgpro/), [iStatMenus](https://bjango.com/mac/istatmenus/) |
| **CPU-based model gating** | [LM Studio](https://lmstudio.ai) auto-load, [Jan.ai](https://jan.ai) background services |
| **Zero-config thermal management** | [Turbo Boost Switcher](https://tbswitcher.rugarciap.com), paid thermal apps |

---

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=hmzainjamil/claude-thermal-optimizer&type=Date)](https://star-history.com/#hmzainjamil/claude-thermal-optimizer&Date)

---

<div align="center">
Built by <a href="https://github.com/hmzainjamil">HMZ</a> · Runs on Claude Code + DigiMinds AI Stack
</div>
