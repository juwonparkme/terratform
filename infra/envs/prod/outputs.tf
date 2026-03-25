output "name_prefix" {
  description = "Computed name prefix for prod resources."
  value       = module.deeplx_proxy.name_prefix
}

output "artifact_bucket_name" {
  description = "Artifact bucket name."
  value       = module.deeplx_proxy.artifact_bucket_name
}

output "alb_dns_name" {
  description = "ALB DNS name."
  value       = module.deeplx_proxy.alb_dns_name
}

output "base_url" {
  description = "Public base URL."
  value       = module.deeplx_proxy.base_url
}

output "lambda_function_names" {
  description = "Lambda function names."
  value       = module.deeplx_proxy.lambda_function_names
}

output "proxy_commit_urls" {
  description = "Commit endpoint URLs."
  value       = module.deeplx_proxy.proxy_commit_urls
}

output "route53_record_fqdn" {
  description = "Route53 record FQDN when configured."
  value       = module.deeplx_proxy.route53_record_fqdn
}

output "tags" {
  description = "Merged default tags for prod resources."
  value       = module.deeplx_proxy.tags
}

output "vpc_enabled" {
  description = "Whether prod VPC mode is enabled."
  value       = module.deeplx_proxy.vpc_enabled
}
