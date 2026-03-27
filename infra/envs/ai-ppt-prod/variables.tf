variable "project_name" {
  description = "Project slug."
  type        = string
  default     = "ai-ppt"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "us-east-1"
}

variable "availability_zone" {
  description = "Lightsail availability zone."
  type        = string
  default     = "us-east-1a"
}

variable "blueprint_id" {
  description = "Lightsail blueprint ID."
  type        = string
  default     = "ubuntu_24_04"
}

variable "bundle_id" {
  description = "Lightsail bundle ID."
  type        = string
  default     = "micro_3_0"
}

variable "key_pair_name" {
  description = "Existing Lightsail key pair name."
  type        = string
}

variable "domain_name" {
  description = "Optional Route53 record name."
  type        = string
  default     = null
}

variable "hosted_zone_id" {
  description = "Optional Route53 hosted zone ID."
  type        = string
  default     = null
}

variable "repo_url" {
  description = "Git repository URL to clone on first boot."
  type        = string
  default     = "https://github.com/juwonparkme/ai_ppt.git"
}

variable "repo_branch" {
  description = "Git branch to clone on first boot."
  type        = string
  default     = "main"
}

variable "app_directory" {
  description = "Absolute directory where the app repo will live on the instance."
  type        = string
  default     = "/opt/ai-ppt"
}

variable "bootstrap_packages" {
  description = "APT packages installed during first boot."
  type        = list(string)
  default = [
    "ca-certificates",
    "curl",
    "git",
    "docker.io",
    "docker-compose-plugin",
  ]
}

variable "bootstrap_post_clone_commands" {
  description = "Additional shell commands executed after repo clone/update."
  type        = list(string)
  default     = []
}

variable "public_ports" {
  description = "Public ports to open."
  type = list(object({
    from_port = number
    to_port   = number
    protocol  = string
  }))
  default = [
    {
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
    },
    {
      from_port = 80
      to_port   = 80
      protocol  = "tcp"
    },
    {
      from_port = 443
      to_port   = 443
      protocol  = "tcp"
    },
  ]
}

variable "tags" {
  description = "Extra tags."
  type        = map(string)
  default     = {}
}
