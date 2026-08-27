resource "aws_vpc" "this" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = terraform.workspace
  }
}

resource "aws_subnet" "managed" {
  for_each = var.subnets_config
  
  vpc_id                 = aws_vpc.this.id
  cidr_block             = each.value.cidr_block
  availability_zone      = each.value.availability_zone
  map_public_ip_on_launch = each.value.is_public

  tags = {
    Name = each.key
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "internet gateway ${terraform.workspace}"
  }
}

resource "aws_route_table" "public" {  
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "nat eip ${terraform.workspace}"
  }
}

resource "aws_nat_gateway" "this" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.managed["public-us-east-1a"].id
  
  tags = {
    Name="nat gateway ${terraform.workspace}"}
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id

  }
}


resource "aws_route_table_association" "managed" {
  for_each = var.subnets_config
  subnet_id      = aws_subnet.managed[each.key].id
  route_table_id = each.value.is_public ? aws_route_table.public.id : aws_route_table.private.id
}
