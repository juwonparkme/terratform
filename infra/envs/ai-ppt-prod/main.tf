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
    repo_url    = var.repo_url
    repo_branch = var.repo_branch
  })
}
