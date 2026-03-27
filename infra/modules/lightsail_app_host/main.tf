locals {
  static_ip_name = "${var.name}-ip"
}

resource "aws_lightsail_instance" "this" {
  name              = var.name
  availability_zone = var.availability_zone
  blueprint_id      = var.blueprint_id
  bundle_id         = var.bundle_id
  key_pair_name     = var.key_pair_name
  user_data         = var.user_data
  tags              = var.tags
}

resource "aws_lightsail_static_ip" "this" {
  count = var.attach_static_ip ? 1 : 0

  name = local.static_ip_name
}

resource "aws_lightsail_static_ip_attachment" "this" {
  count = var.attach_static_ip ? 1 : 0

  static_ip_name = aws_lightsail_static_ip.this[0].name
  instance_name  = aws_lightsail_instance.this.name
}

resource "aws_lightsail_instance_public_ports" "this" {
  instance_name = aws_lightsail_instance.this.name

  dynamic "port_info" {
    for_each = var.public_ports

    content {
      from_port = port_info.value.from_port
      to_port   = port_info.value.to_port
      protocol  = port_info.value.protocol
    }
  }
}

resource "aws_route53_record" "this" {
  count = var.domain_name != null && var.hosted_zone_id != null ? 1 : 0

  zone_id = var.hosted_zone_id
  name    = var.domain_name
  type    = "A"
  ttl     = 300
  records = [coalesce(try(aws_lightsail_static_ip.this[0].ip_address, null), aws_lightsail_instance.this.public_ip_address)]
}
