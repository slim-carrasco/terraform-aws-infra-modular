resource "aws_instance" "this" {
  ami = data.aws_ami.this.id
  instance_type = var.bastion_enable ? "t3.micro" :"t3.small"
  subnet_id = var.subnets_id["public-us-east-1a"]
  key_name= var.key_name

  vpc_security_group_ids = [var.sg_id]

  iam_instance_profile = var.instance_profile_name
   user_data = <<-EOF
              #!/bin/bash
              sudo apt install -y nginx
              
              EOF
  tags = {
    Name = var.bastion_enable ? "bastion server" : "web server"
  }
}
data "aws_ami" "this" {
  most_recent = true
  owners = ["099720109477"]

  filter {
    name = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-*"]
  }



}
