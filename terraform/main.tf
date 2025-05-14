provider "aws" {
  region = "eu-north-1"
}

data "aws_vpc" "default" {
  default = true
}

resource "aws_security_group" "backend_sg" {
  name        = "backend-sg"
  description = "Allow SSH, HTTP and app port"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "App port 5000"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

resource "aws_launch_template" "backend_lt" {
  name_prefix   = "backend-lt-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name      = "myKey"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.backend_sg.id]
  }

  user_data = base64encode(file("user-data.sh"))
}

output "launch_template_id" {
  value = aws_launch_template.backend_lt.id
}