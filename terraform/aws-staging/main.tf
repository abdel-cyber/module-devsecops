terraform {
  required_providers {
    aws    = { source = "hashicorp/aws", version = "~> 5.0" }
    tls    = { source = "hashicorp/tls", version = "~> 4.0" }
  }
}

provider "aws" {
  region = var.aws_region
}

# Utiliser la VPC par défaut
data "aws_vpc" "default" {
  default = true
}
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Security Group : HTTP 80 (accès web) et SSH 22 (dépannage)
resource "aws_security_group" "staging_sg" {
  name        = "tp-devsecops-staging-sg"
  description = "HTTP 80, SSH 22 pour TP staging"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
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

# Clé SSH pour se connecter à l'instance (optionnel)
resource "tls_private_key" "staging" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
resource "aws_key_pair" "staging" {
  key_name   = "tp-staging-key"
  public_key = tls_private_key.staging.public_key_openssh
}

# AMI Amazon Linux 2
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Script user_data : installer Docker, login registry, pull, run
resource "aws_instance" "staging" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type           = var.instance_type
  key_name               = aws_key_pair.staging.key_name
  vpc_security_group_ids = [aws_security_group.staging_sg.id]
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]

  user_data = <<-EOT
#!/bin/bash
set -e
yum update -y
yum install -y docker
systemctl start docker
systemctl enable docker
echo "${var.registry_password}" | docker login -u "${var.registry_user}" --password-stdin ${var.registry_url}
docker pull ${var.docker_image}:${var.docker_tag}
docker stop app 2>/dev/null || true
docker rm app 2>/dev/null || true
docker run -d --name app --restart unless-stopped -p 80:3000 ${var.docker_image}:${var.docker_tag}
EOT

  tags = { Name = "tp-devsecops-staging" }
}
