output "instance_name" {
  value = aws_lightsail_instance.this.name
}

output "instance_public_ip" {
  value = aws_lightsail_instance.this.public_ip_address
}

output "static_ip" {
  value = try(aws_lightsail_static_ip.this[0].ip_address, null)
}

output "domain_name" {
  value = try(aws_route53_record.this[0].fqdn, null)
}
