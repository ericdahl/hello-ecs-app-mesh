# not strictly needed for Fargate , but EC2 doesn't allow private awsvpc ENIs

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.default.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.100.0/24"
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.default.id
}

resource "aws_route_table_association" "private" {
  route_table_id = aws_route_table.private.id
  subnet_id      = aws_subnet.private.id
}

resource "aws_route" "private_nat_gw" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.default.id
}

resource "aws_eip" "nat_gw" {}

resource "aws_nat_gateway" "default" {
  allocation_id = aws_eip.nat_gw.allocation_id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.default]
}