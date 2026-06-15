# ─────────────────────────────────────────────────────────────────────────────
# Docker Container — The actual workspace runtime
# ─────────────────────────────────────────────────────────────────────────────

# ─── Persistent Volume for Home Directory ───

resource "docker_volume" "home" {
  name = "coder-${local.owner_name}-${local.workspace_name}-home"

  labels {
    label = "coder.owner"
    value = local.owner_name
  }
  labels {
    label = "coder.workspace"
    value = local.workspace_name
  }

  lifecycle {
    ignore_changes = all
  }
}

# ─── Docker Image (Ubuntu — lightweight base for code-server workspace) ───

resource "docker_image" "workspace" {
  name = "ubuntu:24.04"
}

# ─── Docker Container ───

resource "docker_container" "workspace" {
  name  = local.container_name
  image = docker_image.workspace.image_id

  privileged = false

  # Coder agent token — allows the agent to phone home
  env = [
    "CODER_AGENT_TOKEN=${coder_agent.main.token}",
  ]

  # Entry point: install basics, create coder user, start Coder agent
  user = "root"
  entrypoint = ["bash", "-c", templatefile("${path.module}/scripts/entrypoint.sh", {
    workspace_name  = data.coder_workspace.me.name
    pkg_install_b64 = base64encode(file("${path.module}/scripts/pkg-install.sh"))
    init_script     = coder_agent.main.init_script
  })]

  # Resource limits
  memory  = data.coder_parameter.memory_gb.value * 1024 # Convert GB to MB
  cpu_set = "0-${data.coder_parameter.cpu_cores.value - 1}"

  # Persistent home directory
  volumes {
    volume_name    = docker_volume.home.name
    container_path = "/home/coder"
    read_only      = false
  }


  # Hostname
  hostname = local.workspace_name

  # Keep running
  restart = "unless-stopped"

  # Labels for management
  labels {
    label = "coder.owner"
    value = local.owner_name
  }
  labels {
    label = "coder.workspace"
    value = local.workspace_name
  }
  labels {
    label = "coder.template"
    value = "code-server"
  }

  lifecycle {
    ignore_changes = [image]
  }
}
