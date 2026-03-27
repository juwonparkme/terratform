variable "name" {
  description = "Lightsail instance name."
  type        = string
}

variable "availability_zone" {
  description = "Lightsail availability zone."
  type        = string
}

variable "blueprint_id" {
  description = "Lightsail blueprint ID."
  type        = string
}

variable "bundle_id" {
  description = "Lightsail bundle ID."
  type        = string
}

variable "key_pair_name" {
  description = "Existing Lightsail key pair name."
  type        = string
  default     = null
}

variable "user_data" {
  description = "Cloud-init or shell user data."
  type        = string
  default     = null
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

variable "attach_static_ip" {
  description = "Whether to allocate and attach a static IP."
  type        = bool
  default     = true
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

variable "tags" {
  description = "Tags applied to resources."
  type        = map(string)
  default     = {}
}
