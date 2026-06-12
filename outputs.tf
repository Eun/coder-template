# ─────────────────────────────────────────────────────────────────────────────
# Outputs
# ─────────────────────────────────────────────────────────────────────────────

output "workspace_url" {
  description = "URL to access the Coder workspace"
  value       = data.coder_workspace.me.access_url
}

output "container_name" {
  description = "Name of the Docker container"
  value       = docker_container.workspace.name
}

output "volume_name" {
  description = "Name of the persistent Docker volume"
  value       = docker_volume.home.name
}
