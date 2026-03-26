variable "project_name" {
  description = "Project slug used for naming."
  type        = string
  default     = "deeplx-proxy"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "Primary AWS region."
  type        = string
  default     = "us-east-1"
}

variable "lambda_size" {
  description = "Number of proxy Lambda functions to create."
  type        = number
  default     = 15
}

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
  default     = "python3.12"
}

variable "lambda_handler" {
  description = "Lambda handler path."
  type        = string
  default     = "service/main.handler"
}

variable "lambda_architectures" {
  description = "Lambda instruction set architectures."
  type        = list(string)
  default     = ["x86_64"]
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB."
  type        = number
  default     = 256
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
  default     = 300
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention."
  type        = number
  default     = 14
}

variable "lambda_app_archive_path" {
  description = "Local path to the zipped Lambda application artifact."
  type        = string
  default     = "../../../dist/lambda-app.zip"
}

variable "lambda_layer_archive_path" {
  description = "Local path to the zipped Lambda dependency layer artifact."
  type        = string
  default     = "../../../dist/lambda-layer.zip"
}

variable "lambda_app_s3_key" {
  description = "S3 key for the Lambda application artifact."
  type        = string
  default     = "apps/lambda-app.zip"
}

variable "artifact_bucket_name" {
  description = "Globally unique S3 bucket name for artifacts."
  type        = string
  default     = "change-me-deeplx-proxy-prod-artifacts"
}

variable "artifact_bucket_force_destroy" {
  description = "Whether to allow automatic artifact bucket deletion."
  type        = bool
  default     = false
}

variable "create_vpc" {
  description = "Whether to create a dedicated VPC."
  type        = bool
  default     = true
}

variable "enable_vpc" {
  description = "Whether to place Lambdas in a VPC."
  type        = bool
  default     = false
}

variable "availability_zones" {
  description = "Availability zones for the managed VPC."
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "vpc_cidr" {
  description = "CIDR block for the managed VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks for the managed VPC."
  type        = list(string)
  default     = ["10.30.10.0/24", "10.30.11.0/24"]
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks for the managed VPC."
  type        = list(string)
  default     = ["10.30.1.0/24", "10.30.2.0/24"]
}

variable "vpc_id" {
  description = "Existing VPC ID when create_vpc is false."
  type        = string
  default     = null
}

variable "public_subnet_ids" {
  description = "Existing public subnet IDs when create_vpc is false."
  type        = list(string)
  default     = []
}

variable "private_subnet_ids" {
  description = "Existing private subnet IDs when create_vpc is false."
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "Optional ACM certificate ARN."
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Optional public DNS name."
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Optional Route53 hosted zone ID."
  type        = string
  default     = null
}

variable "alb_deletion_protection" {
  description = "Whether to enable ALB deletion protection."
  type        = bool
  default     = false
}

variable "environment_variables" {
  description = "Additional Lambda environment variables."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Additional resource tags."
  type        = map(string)
  default     = {}
}
