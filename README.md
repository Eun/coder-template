# code-server Workspace

Coder template that provisions a single Docker container with **code-server** (VS Code in browser), **JetBrains IDE support** (via Gateway), **git clone**, and **git commit signing** — all sharing the same filesystem.

## Architecture

```
┌──────────────────── Coder Workspace (Docker container) ────────────────────┐
│                                                                            │
│  Base Image: ubuntu:24.04 (stock — tools installed at first startup)       │
│  Mode: unprivileged (privileged = false)                                   │
│                                                                            │
│  ┌────────────────────┐  ┌────────────────────┐                            │
│  │   code-server       │  │   JetBrains IDE    │                            │
│  │   (port 8080)       │  │   (via Gateway)    │                            │
│  │                     │  │                     │                            │
│  │   Browser IDE for   │  │   GoLand, IntelliJ │                            │
│  │   editing and       │  │   PyCharm, etc.    │                            │
│  │   code review       │  │                     │                            │
│  └─────────┬──────────┘  └─────────┬──────────┘                            │
│            │                       │                                       │
│              Shared filesystem                                             │
│              /home/coder/<workspace-name>                                   │
│              (Coder persistent volume)                                     │
│                                                                            │
└────────────────────────────────────────────────────────────────────────────┘
```

## What's Included

| Component | Purpose |
|---|---|
| **code-server** (port 8080) | VS Code in the browser for editing and code review |
| **JetBrains IDE** (via Gateway) | GoLand, IntelliJ IDEA, PyCharm, WebStorm, CLion, and more — connect from your local JetBrains Gateway |
| **Git clone** | Auto-clone a repo into `/home/coder/<workspace-name>` on startup |
| **Git commit signing** | SSH-based commit signing via Coder's git SSH key |

## JetBrains IDE Support

Select a JetBrains IDE when creating your workspace. Supported IDEs:

| IDE | Parameter Value |
|---|---|
| GoLand | `GO` |
| IntelliJ IDEA Ultimate | `IU` |
| IntelliJ IDEA Community | `IC` |
| PyCharm Professional | `PY` |
| PyCharm Community | `PC` |
| WebStorm | `WS` |
| PhpStorm | `PS` |
| CLion | `CL` |
| RubyMine | `RM` |
| Rider | `RD` |
| RustRover | `RR` |

**How to connect:**
1. Select your preferred IDE when creating the workspace
2. Install [JetBrains Gateway](https://www.jetbrains.com/remote-development/gateway/) on your local machine
3. Install the Coder plugin in Gateway
4. Connect to your workspace — the IDE backend runs in the container, the UI runs locally

## Parameters

When creating a workspace, you'll be prompted for:

| Parameter | Required | Default | Description |
|---|---|---|---|
| Git Name | No | — | `git config user.name` |
| Git Email | No | — | `git config user.email` |
| Git Repository URL | No | — | Repo to clone into `/home/coder/<workspace-name>` |
| Git Branch | No | — | Branch to check out |
| Dotfiles Repository | No | — | Applied via `coder dotfiles` on startup |
| GitHub Token | No | — | Personal access token for GitHub CLI |
| JetBrains IDE | No | None | JetBrains IDE to use via Gateway |
| CPU Cores | No | 4 | 2 / 4 / 8 cores |
| Memory (GB) | No | 4 | 2 / 4 / 8 / 16 GB |
| Disk Size (GB) | No | 20 | 10 / 20 / 50 / 100 GB |

## Resource Sizing Guide

| Workload | CPU | Memory | Disk | Notes |
|---|---|---|---|---|
| Light (small repos) | 2 | 2 GB | 10 GB | Minimum viable |
| **Medium (recommended)** | **4** | **4 GB** | **20 GB** | Medium repos, builds |
| Heavy (large projects, builds) | 8 | 8 GB | 50 GB | Complex projects |

Memory breakdown at 4 GB: ~2 GB code-server, ~2 GB headroom for builds and tools. JetBrains IDEs may need 4–8 GB for comfortable use.

## Usage

### Push the template

```bash
coder templates push code-server-workspace --directory .
```

### Create a workspace

```bash
coder create my-workspace --template code-server-workspace
```

### Access services

- **code-server**: Click "VS Code (Browser)" in the Coder dashboard
- **JetBrains IDE**: Open JetBrains Gateway → Coder plugin → select workspace
- **Terminal**: Use the web terminal or SSH

## File Structure

```
├── main.tf          # Providers, data sources, locals, git-clone module, git signing, JetBrains module
├── variables.tf     # Coder parameters (git config, IDE selection, resources)
├── agent.tf         # Coder agent, env vars, metadata, startup scripts
├── apps.tf          # coder_app resources (code-server)
├── container.tf     # Docker volume, Ubuntu image, unprivileged container
├── outputs.tf       # Workspace URL, container name, volume name
├── config/
│   └── settings.json # Default code-server settings (deployed on first start)
└── README.md
```

## Security Notes

- Container runs as **unprivileged** (`privileged = false`).
- Git commit signing uses SSH keys fetched from Coder's agent API.
- All Coder apps use `share = "owner"` — only the workspace owner can access them.
- Outbound internet access is required for git operations and package installation.

## Known Issues

| Issue | Workaround |
|---|---|
| First startup is slow (installs all deps) | Subsequent starts use cached marker files and skip installation |
| code-server extensions from Open VSX may be outdated | Install specific `.vsix` files in startup script if needed |
| `disk_gb` parameter doesn't enforce volume size | Docker local volumes don't support size limits; parameter is informational |
| JetBrains IDE download on first start takes time | IDE is cached in persistent volume after first download |

## Verification Checklist

After deploying, verify:

- [ ] Workspace starts and Coder agent connects (green status)
- [ ] code-server opens in browser and shows project directory
- [ ] JetBrains Gateway connects and IDE opens (if selected)
- [ ] Git repo is cloned (if configured)
- [ ] Git commit signing works (`git log --show-signature`)
- [ ] Workspace stop/start preserves files in `/home/coder`
- [ ] Dashboard metadata shows correct status
