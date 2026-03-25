output "name_prefix" {
  description = "Computed name prefix for downstream resources."
  value       = local.name_prefix
}

output "artifact_bucket_name" {
  description = "Artifact bucket name."
  value       = aws_s3_bucket.artifacts.bucket
}

output "alb_dns_name" {
  description = "Application Load Balancer DNS name."
  value       = aws_lb.this.dns_name
}

output "base_url" {
  description = "Base URL for the public proxy."
  value       = local.base_url
}

output "lambda_function_names" {
  description = "Provisioned Lambda function names."
  value       = aws_lambda_function.proxy[*].function_name
}

output "proxy_commit_urls" {
  description = "Commit endpoint URLs."
  value = [
    for index in local.function_indexes :
    "${local.base_url}/v${index}/commit"
  ]
}

output "route53_record_fqdn" {
  description = "Route53 record FQDN when DNS is enabled."
  value       = try(aws_route53_record.alb[0].fqdn, null)
}

output "tags" {
  description = "Merged default tags."
  value       = local.tags
}

output "vpc_enabled" {
  description = "Whether VPC mode is enabled."
  value       = var.enable_vpc
}
