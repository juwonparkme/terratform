locals {
  default_bootstrap_post_clone_commands = [
    "if [ ! -f ${var.app_directory}/deploy/lightsail/app.env ]; then cp ${var.app_directory}/deploy/lightsail/app.env.example ${var.app_directory}/deploy/lightsail/app.env; fi",
    "mkdir -p ${var.app_directory}/deploy/lightsail/secrets",
    "chown -R ubuntu:ubuntu ${var.app_directory}",
  ]
  effective_bootstrap_post_clone_commands = length(var.bootstrap_post_clone_commands) > 0 ? var.bootstrap_post_clone_commands : local.default_bootstrap_post_clone_commands
}

module "ai_ppt_lightsail" {
  source = "../../modules/lightsail_app_host"

  name              = "${var.project_name}-${var.environment}"
  availability_zone = var.availability_zone
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = var.key_pair_name
  public_ports      = var.public_ports
  domain_name       = var.domain_name
  hosted_zone_id    = var.hosted_zone_id
  tags              = local.default_tags
  user_data = templatefile("${path.module}/user-data.sh.tftpl", {
    repo_url                      = var.repo_url
    repo_branch                   = var.repo_branch
    app_directory                 = var.app_directory
    bootstrap_packages            = join(" ", var.bootstrap_packages)
    bootstrap_post_clone_commands = join("\n", local.effective_bootstrap_post_clone_commands)
  })
}
