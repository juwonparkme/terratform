variable "project_name" {
  description = "Project slug used for naming."
  type        = string
}

variable "environment" {
  description = "Environment name."
  type        = string
}

variable "aws_region" {
  description = "Primary AWS region."
  type        = string
}

variable "lambda_size" {
  description = "Number of proxy Lambda functions to create."
  type        = number
}

variable "lambda_runtime" {
  description = "Lambda runtime."
  type        = string
}

variable "lambda_handler" {
  description = "Lambda handler path."
  type        = string
}

variable "lambda_architectures" {
  description = "Lambda instruction set architectures."
  type        = list(string)
}

variable "lambda_memory_size" {
  description = "Lambda memory size in MB."
  type        = number
}

variable "lambda_timeout" {
  description = "Lambda timeout in seconds."
  type        = number
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention."
  type        = number
}

variable "lambda_app_archive_path" {
  description = "Local path to the zipped Lambda application artifact."
  type        = string
}

variable "lambda_layer_archive_path" {
  description = "Local path to the zipped Lambda dependency layer artifact."
  type        = string
}

variable "lambda_app_s3_key" {
  description = "S3 key for the Lambda application artifact."
  type        = string
}

variable "artifact_bucket_name" {
  description = "Globally unique S3 bucket name for artifacts."
  type        = string
}

variable "artifact_bucket_force_destroy" {
  description = "Whether to allow automatic artifact bucket deletion."
  type        = bool
  default     = false
}

variable "create_vpc" {
  description = "Whether to create a dedicated VPC for the ALB and optional Lambda networking."
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
  default     = []
}

variable "vpc_cidr" {
  description = "CIDR block for the managed VPC."
  type        = string
  default     = "10.30.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Public subnet CIDR blocks for the managed VPC."
  type        = list(string)
  default     = []
}

variable "private_subnet_cidrs" {
  description = "Private subnet CIDR blocks for the managed VPC."
  type        = list(string)
  default     = []
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
  description = "Existing private subnet IDs when create_vpc is false and enable_vpc is true."
  type        = list(string)
  default     = []
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
  default     = null
}

variable "domain_name" {
  description = "Optional public DNS name for the ALB."
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
