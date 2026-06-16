# ─────────────────────────────────────────────────────────────────────────────
# Coder Agent — Runs inside the container
# ─────────────────────────────────────────────────────────────────────────────

resource "coder_agent" "main" {
  os   = "linux"
  arch = data.coder_provisioner.me.arch

  startup_script_behavior = "blocking"

  display_apps {
    vscode                 = true
    vscode_insiders        = false
    ssh_helper             = true
    port_forwarding_helper = true
    web_terminal           = true
  }

  env = {
    GIT_AUTHOR_NAME     = data.coder_parameter.git_user_name.value
    GIT_COMMITTER_NAME  = data.coder_parameter.git_user_name.value
    GIT_AUTHOR_EMAIL    = data.coder_parameter.git_user_email.value
    GIT_COMMITTER_EMAIL = data.coder_parameter.git_user_email.value
    WORKSPACE_BASE      = "/home/coder/${data.coder_workspace.me.name}"
    PROJECT_DIR         = "/home/coder/${data.coder_workspace.me.name}"
    HOME_DIR            = "/home/coder"
    GITHUB_TOKEN        = data.coder_parameter.github_token.value
    DOTFILES_REPO       = data.coder_parameter.dotfiles_repo.value
    GH_WEB_AUTH_BASE_PATH = "/@${data.coder_workspace_owner.me.name}/${data.coder_workspace.me.name}.${local.agent_name}/apps/gh-web-auth/"
    JETBRAINS_IDE_CODE    = data.coder_parameter.jetbrains_ide.value
    JETBRAINS_IDE_BUILD   = local.jetbrains_ide_build
  }

  # ─── Agent Metadata (shown in Coder dashboard) ───

  metadata {
    key          = "cpu"
    display_name = "CPU Cores"
    script       = "nproc"
    interval     = 60
    timeout      = 5
  }

  metadata {
    key          = "memory"
    display_name = "Memory Usage"
    script       = "free -h | awk '/Mem:/ {print $3 \" / \" $2}'"
    interval     = 60
    timeout      = 5
  }

  metadata {
    key          = "disk"
    display_name = "Disk Usage"
    script       = "df -h /home/coder | awk 'NR==2 {print $3 \" / \" $2}'"
    interval     = 300
    timeout      = 5
  }

  metadata {
    key          = "code_server_status"
    display_name = "code-server"
    script       = "curl -s http://localhost:13337/healthz >/dev/null 2>&1 && echo '✅ running' || echo '⏳ starting'"
    interval     = 10
    timeout      = 5
  }

  dynamic "metadata" {
    for_each = data.coder_parameter.jetbrains_ide.value != "none" ? [1] : []
    content {
      key          = "jetbrains_status"
      display_name = "JetBrains IDE"
      script       = <<-EOT
        IDE_DIR="/root/.cache/JetBrains/RemoteDev/dist/$${JETBRAINS_IDE_CODE}-$${JETBRAINS_IDE_BUILD}"
        if [ -f "$IDE_DIR/.expandSucceeded" ] && [ -f "$IDE_DIR/product-info.json" ]; then
          echo "✅ ready"
        else
          echo "⏳ preloading"
        fi
      EOT
      interval     = 10
      timeout      = 5
    }
  }

  metadata {
    key          = "gh_auth_status"
    display_name = "GitHub Auth"
    script       = <<-EOT
      resp=$(curl -sf http://localhost:18515/api/status 2>/dev/null) || { echo "⏳ starting"; exit 0; }
      user=$(echo "$resp" | jq -r '.user // empty' 2>/dev/null)
      if [ -n "$user" ]; then
        echo "✅ $user"
      else
        echo "❌ not authenticated"
      fi
    EOT
    interval     = 10
    timeout      = 5
  }
}

# ─────────────────────────────────────────────────────────────────────────────
# Startup Scripts
# ─────────────────────────────────────────────────────────────────────────────

# ── Install Dependencies ──

resource "coder_script" "configure_mise" {
  agent_id           = coder_agent.main.id
  display_name       = "Install mise"
  icon               = "/icon/coder.svg"
  run_on_start       = true
  start_blocks_login = true
  script             = file("${path.module}/scripts/configure-mise.sh")
}



# ── Git Configuration ──

resource "coder_script" "git_config" {
  agent_id           = coder_agent.main.id
  display_name       = "Git Configuration"
  icon               = "/icon/git.svg"
  run_on_start       = true
  start_blocks_login = true
  script             = file("${path.module}/scripts/git-config.sh")
}

# ── GitHub CLI Authentication (optional) ──

resource "coder_script" "configure_gh" {
  agent_id           = coder_agent.main.id
  display_name       = "GitHub CLI Auth"
  icon               = "/icon/github.svg"
  run_on_start       = true
  start_blocks_login = true
  script             = file("${path.module}/scripts/configure-gh.sh")
}

# ── gh-web-auth (GitHub OAuth web UI) ──

resource "coder_script" "gh_web_auth" {
  agent_id           = coder_agent.main.id
  display_name       = "gh-web-auth"
  icon               = "/icon/github.svg"
  run_on_start       = true
  start_blocks_login = false
  script             = file("${path.module}/scripts/gh-web-auth.sh")
}

resource "coder_app" "gh_web_auth" {
  agent_id     = coder_agent.main.id
  slug         = "gh-web-auth"
  display_name = "GitHub Auth"
  icon         = "/icon/github.svg"
  url          = "http://localhost:18515"
  subdomain    = false
  share        = "owner"

  healthcheck {
    url       = "http://localhost:18515/api/status"
    interval  = 10
    threshold = 5
  }
}

# ── Dotfiles (optional) ──

resource "coder_script" "dotfiles" {
  count              = data.coder_parameter.dotfiles_repo.value != "" ? 1 : 0
  agent_id           = coder_agent.main.id
  display_name       = "Dotfiles"
  icon               = "/icon/dotfiles.svg"
  run_on_start       = true
  start_blocks_login = true
  script             = file("${path.module}/scripts/dotfiles.sh")
}

