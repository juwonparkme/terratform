locals {
  name_prefix       = lower("${var.project_name}-${var.environment}")
  short_name_prefix = substr(local.name_prefix, 0, 20)

  default_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Project     = var.project_name
  }

  tags = merge(local.default_tags, var.tags)

  https_enabled = var.certificate_arn != null && trimspace(var.certificate_arn) != ""
  dns_enabled = (
    var.domain_name != null &&
    trimspace(var.domain_name) != "" &&
    var.hosted_zone_id != null &&
    trimspace(var.hosted_zone_id) != ""
  )

  vpc_id = var.create_vpc ? module.vpc[0].vpc_id : var.vpc_id

  public_subnet_ids = var.create_vpc ? module.vpc[0].public_subnets : var.public_subnet_ids
  private_subnet_ids = (
    var.enable_vpc ?
    (var.create_vpc ? module.vpc[0].private_subnets : var.private_subnet_ids) :
    []
  )

  function_indexes = range(var.lambda_size)
  function_names = [
    for index in local.function_indexes :
    substr("${local.name_prefix}-${index}", 0, 64)
  ]
  target_group_names = [
    for index in local.function_indexes :
    substr("${local.short_name_prefix}-${index}-tg", 0, 32)
  ]
  endpoint_scheme = local.https_enabled ? "https" : "http"
  base_url        = local.dns_enabled ? "${local.endpoint_scheme}://${var.domain_name}" : "${local.endpoint_scheme}://${aws_lb.this.dns_name}"
}

check "network_inputs" {
  assert {
    condition = (
      var.create_vpc ||
      (
        var.vpc_id != null &&
        length(var.public_subnet_ids) >= 2 &&
        (!var.enable_vpc || length(var.private_subnet_ids) >= 2)
      )
    )
    error_message = "When create_vpc is false, provide vpc_id, at least two public_subnet_ids, and private_subnet_ids when enable_vpc is true."
  }
}

check "artifact_inputs" {
  assert {
    condition = (
      trimspace(var.artifact_bucket_name) != "" &&
      trimspace(var.lambda_app_archive_path) != "" &&
      trimspace(var.lambda_layer_archive_path) != ""
    )
    error_message = "artifact_bucket_name, lambda_app_archive_path, and lambda_layer_archive_path must be set."
  }
}
