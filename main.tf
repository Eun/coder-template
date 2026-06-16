# ─────────────────────────────────────────────────────────────────────────────
# Coder Template: code-server Workspace
# ─────────────────────────────────────────────────────────────────────────────
# Single Docker container with:
#   - code-server (VS Code in browser, port 13337)
#   - JetBrains IDE support via Gateway (GoLand, IntelliJ, PyCharm, etc.)
#   - Git clone + commit signing
#   - Shared filesystem at /home/coder/<workspace-name>
# ─────────────────────────────────────────────────────────────────────────────

terraform {
  required_version = ">= 1.3.0"

  required_providers {
    coder = {
      source  = "coder/coder"
      version = ">= 0.17.0"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = ">= 3.0.0"
    }
    http = {
      source  = "hashicorp/http"
      version = ">= 3.0.0"
    }
  }
}

provider "docker" {}
provider "coder" {}

# ─── Data Sources ───

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "coder_provisioner" "me" {}

locals {
  agent_name     = "main"
  workspace_name = lower(data.coder_workspace.me.name)
  owner_name     = lower(data.coder_workspace_owner.me.name)
  container_name = "coder-${local.owner_name}-${local.workspace_name}"
  project_dir    = "/home/coder/${data.coder_workspace.me.name}"
  home_dir       = "/home/coder"
}

# ─── Git Clone Module ───

module "git_clone" {
  count       = data.coder_parameter.git_repo.value != "" ? 1 : 0
  source      = "registry.coder.com/modules/git-clone/coder"
  version     = ">= 1.0.0"
  agent_id    = coder_agent.main.id
  url         = data.coder_parameter.git_repo.value
  base_dir    = local.home_dir
  folder_name = data.coder_workspace.me.name
  branch_name = data.coder_parameter.git_branch.value

  pre_clone_script = file("${path.module}/scripts/pre-clone.sh")
}

# ─── Git Commit Signing ───

resource "coder_script" "git_signing" {
  agent_id           = coder_agent.main.id
  display_name       = "Git Commit Signing"
  icon               = "/icon/git.svg"
  run_on_start       = true
  start_blocks_login = true
  script             = file("${path.module}/scripts/git-signing.sh")
}


module "code-server" {
  count     = data.coder_workspace.me.start_count
  source    = "registry.coder.com/coder/code-server/coder"
  version   = "1.5.0"
  agent_id  = coder_agent.main.id
  folder    = "/home/coder/${data.coder_workspace.me.name}"
  port      = 13337
  subdomain = false
}

# ─── JetBrains IDE (via Gateway) ───

module "jetbrains" {
  count      = data.coder_parameter.jetbrains_ide.value != "none" ? data.coder_workspace.me.start_count : 0
  source     = "registry.coder.com/modules/jetbrains/coder"
  version    = "1.1.1"
  agent_id   = coder_agent.main.id
  agent_name = local.agent_name
  folder     = "/home/coder/${data.coder_workspace.me.name}"
  default    = [data.coder_parameter.jetbrains_ide.value]
  options    = [data.coder_parameter.jetbrains_ide.value]
}

# ─── JetBrains IDE Preload ───

# Fetch the latest build number for the selected IDE at plan time.
# This is the same API call the jetbrains module makes internally,
# but done independently to avoid a dependency cycle
# (module.jetbrains depends on coder_agent, so the agent env
# cannot reference the module output).
data "http" "jetbrains_release" {
  count = data.coder_parameter.jetbrains_ide.value != "none" ? 1 : 0
  url   = "https://data.services.jetbrains.com/products/releases?code=${data.coder_parameter.jetbrains_ide.value}&type=release&latest=true"
}

locals {
  jetbrains_ide_build = (
    length(data.http.jetbrains_release) > 0
    ? jsondecode(data.http.jetbrains_release[0].response_body)[keys(jsondecode(data.http.jetbrains_release[0].response_body))[0]][0].build
    : ""
  )
}

resource "coder_script" "jetbrains_preload" {
  count              = data.coder_parameter.jetbrains_ide.value != "none" ? 1 : 0
  agent_id           = coder_agent.main.id
  display_name       = "Pre-download JetBrains IDE"
  icon               = "/icon/jetbrains-toolbox.svg"
  run_on_start       = true
  start_blocks_login = false
  script             = file("${path.module}/scripts/jetbrains-preload.sh")
}
