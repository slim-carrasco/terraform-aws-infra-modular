resource "aws_security_group" "this" {
  name        = var.bastion_enable ? "bastion_sg" : "web_server_sg"
  description = var.bastion_enable ? "Bastion para acceder a servidores privados" : "Security group para permitir el trafico hacia una apgina web dentro de la isntancia"
  vpc_id      = var.vpc_id

  tags = {
    Name = var.environment == "produccion" ? "security-group-${var.environment}" : "security-group-dev"
  } 
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.bastion_enable ? var.bastion_ports : var.web_ports

  security_group_id  = aws_security_group.this.id
  cidr_ipv4          = "0.0.0.0/0"
  from_port          = each.value
  to_port            = each.value
  ip_protocol        = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "this" {
  security_group_id = aws_security_group.this.id
  cidr_ipv4   = "0.0.0.0/0"
  from_port   = 443
  to_port     = 443   
  ip_protocol = "tcp"
  
}
