resource "aws_lb" "virtual_gateway" {
  name               = "virtual-gateway"
  load_balancer_type = "network"
  internal           = false

  subnets = [
    aws_subnet.public.id
  ]
}

resource "aws_lb_listener" "virtual_gateway" {
  load_balancer_arn = aws_lb.virtual_gateway.arn

  port     = 80
  protocol = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.virtual_gateway.arn
  }
}

resource "aws_lb_target_group" "virtual_gateway" {
  vpc_id = aws_vpc.default.id
  name   = "virtual-gateway"

  deregistration_delay = 0
  target_type          = "ip"
  protocol             = "TCP"
  port                 = 8080
}