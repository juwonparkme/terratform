module "deeplx_proxy" {
  source = "../../modules/deeplx_proxy"

  providers = {
    aws           = aws
    aws.us_east_1 = aws.us_east_1
  }

  project_name                  = var.project_name
  environment                   = var.environment
  aws_region                    = var.aws_region
  lambda_size                   = var.lambda_size
  lambda_runtime                = var.lambda_runtime
  lambda_handler                = var.lambda_handler
  lambda_architectures          = var.lambda_architectures
  lambda_memory_size            = var.lambda_memory_size
  lambda_timeout                = var.lambda_timeout
  log_retention_in_days         = var.log_retention_in_days
  lambda_app_archive_path       = var.lambda_app_archive_path
  lambda_layer_archive_path     = var.lambda_layer_archive_path
  lambda_app_s3_key             = var.lambda_app_s3_key
  artifact_bucket_name          = var.artifact_bucket_name
  artifact_bucket_force_destroy = var.artifact_bucket_force_destroy
  create_vpc                    = var.create_vpc
  enable_vpc                    = var.enable_vpc
  availability_zones            = var.availability_zones
  vpc_cidr                      = var.vpc_cidr
  public_subnet_cidrs           = var.public_subnet_cidrs
  private_subnet_cidrs          = var.private_subnet_cidrs
  vpc_id                        = var.vpc_id
  public_subnet_ids             = var.public_subnet_ids
  private_subnet_ids            = var.private_subnet_ids
  certificate_arn               = var.certificate_arn
  domain_name                   = var.domain_name
  hosted_zone_id                = var.hosted_zone_id
  alb_deletion_protection       = var.alb_deletion_protection
  environment_variables         = var.environment_variables
  tags                          = var.tags
}
