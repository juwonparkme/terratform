module "vpc" {
  count   = var.create_vpc ? 1 : 0
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 6.0"

  name = "${local.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.availability_zones
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.enable_vpc ? var.private_subnet_cidrs : []

  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_nat_gateway   = var.enable_vpc
  single_nat_gateway   = var.enable_vpc

  tags = local.tags
}

resource "aws_security_group" "alb" {
  name_prefix = "${local.short_name_prefix}-alb-"
  description = "Security group for DeepLX proxy ALB."
  vpc_id      = local.vpc_id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = local.https_enabled ? [1] : []
    content {
      description = "Allow HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-alb-sg" })
}

resource "aws_security_group" "lambda" {
  count = var.enable_vpc ? 1 : 0

  name_prefix = "${local.short_name_prefix}-fn-"
  description = "Security group for DeepLX proxy Lambdas."
  vpc_id      = local.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.tags, { Name = "${local.name_prefix}-lambda-sg" })
}
