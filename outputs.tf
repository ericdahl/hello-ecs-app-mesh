output "nlb_virtual_gateway" {
  value = "http://${aws_lb.virtual_gateway.dns_name}"
}