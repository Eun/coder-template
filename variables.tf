# ─────────────────────────────────────────────────────────────────────────────
# Coder Parameters — Users fill these at workspace creation / update
# ─────────────────────────────────────────────────────────────────────────────

# ─── Git Configuration ───

data "coder_parameter" "git_user_name" {
  name         = "git_user_name"
  display_name = "Git Name"
  description  = "Your name for git commits (git config user.name)."
  type         = "string"
  default      = ""
  mutable      = true
  order        = 1
}

data "coder_parameter" "git_user_email" {
  name         = "git_user_email"
  display_name = "Git Email"
  description  = "Your email for git commits (git config user.email)."
  type         = "string"
  default      = ""
  mutable      = true
  order        = 2
}

data "coder_parameter" "git_repo" {
  name         = "git_repo"
  display_name = "Git Repository URL"
  description  = "Repository to clone directly into /home/coder/<workspace-name> (not nested in a subfolder). Leave empty to start fresh."
  type         = "string"
  default      = ""
  mutable      = true
  order        = 3
}

data "coder_parameter" "git_branch" {
  name         = "git_branch"
  display_name = "Git Branch"
  description  = "Branch to check out. Leave empty for the default branch."
  type         = "string"
  default      = ""
  mutable      = true
  order        = 4
}

data "coder_parameter" "dotfiles_repo" {
  name         = "dotfiles_repo"
  display_name = "Dotfiles Repository"
  description  = "URL to your dotfiles repo. Applied via 'coder dotfiles' on startup."
  type         = "string"
  default      = ""
  mutable      = true
  order        = 5
}

data "coder_parameter" "github_token" {
  name         = "github_token"
  display_name = "GitHub Token"
  description  = "Personal access token for GitHub CLI (gh). Used for PR operations, repo access, etc."
  type         = "string"
  default      = ""
  mutable      = true
  order        = 6
}

# ─── Resource Limits ───

data "coder_parameter" "cpu_cores" {
  name         = "cpu_cores"
  display_name = "CPU Cores"
  description  = "Number of CPU cores for the workspace."
  type         = "number"
  default      = "4"
  mutable      = true
  order        = 10

  option {
    name  = "2 cores (Light)"
    value = "2"
  }
  option {
    name  = "4 cores (Recommended)"
    value = "4"
  }
  option {
    name  = "8 cores (Heavy)"
    value = "8"
  }
}

data "coder_parameter" "memory_gb" {
  name         = "memory_gb"
  display_name = "Memory (GB)"
  description  = "RAM allocated to the workspace. 4 GB recommended (code-server ~2GB + headroom)."
  type         = "number"
  default      = "4"
  mutable      = true
  order        = 11

  option {
    name  = "2 GB (Light)"
    value = "2"
  }
  option {
    name  = "4 GB (Recommended)"
    value = "4"
  }
  option {
    name  = "8 GB (Heavy)"
    value = "8"
  }
  option {
    name  = "16 GB"
    value = "16"
  }
}

data "coder_parameter" "disk_gb" {
  name         = "disk_gb"
  display_name = "Disk Size (GB)"
  description  = "Persistent storage for /home/coder."
  type         = "number"
  default      = "20"
  mutable      = true
  order        = 12

  option {
    name  = "10 GB (Light)"
    value = "10"
  }
  option {
    name  = "20 GB (Recommended)"
    value = "20"
  }
  option {
    name  = "50 GB (Heavy)"
    value = "50"
  }
  option {
    name  = "100 GB"
    value = "100"
  }
}

# ─── IDE Selection ───

data "coder_parameter" "install_code_server" {
  name         = "install_code_server"
  display_name = "code-server (VS Code in Browser)"
  description  = "Enable code-server (VS Code in the browser) on port 13337."
  type         = "bool"
  default      = "true"
  mutable      = true
  order        = 7

  option {
    name  = "Yes"
    value = "true"
    icon  = "/icon/code.svg"
  }
  option {
    name  = "No"
    value = "false"
    icon  = "/emojis/274c.png"
  }
}

data "coder_parameter" "install_gh" {
  name         = "install_gh"
  display_name = "GitHub CLI (gh)"
  description  = "Install the GitHub CLI (gh) and gh-web-auth for browser-based GitHub authentication."
  type         = "bool"
  default      = "true"
  mutable      = true
  order        = 8

  option {
    name  = "Yes"
    value = "true"
    icon  = "/icon/github.svg"
  }
  option {
    name  = "No"
    value = "false"
    icon  = "/emojis/274c.png"
  }
}

data "coder_parameter" "enable_jetbrains" {
  name         = "enable_jetbrains"
  display_name = "JetBrains IDE"
  description  = "Enable JetBrains IDE selection via Gateway."
  type         = "bool"
  default      = "true"
  mutable      = true
  order        = 9

  option {
    name  = "Yes"
    value = "true"
    icon  = "/icon/gateway.svg"
  }
  option {
    name  = "No"
    value = "false"
    icon  = "/emojis/274c.png"
  }
}


