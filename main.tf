provider "aws" {
  region = "eu-west-1"
}

# EC2 instance for Jenkins + GitHub Runner + MCP Servers
resource "aws_instance" "devops_server" {
  ami           = "ami-0442403fb8d244144"
  instance_type = "t3.medium"
  key_name      = "mnnashyKeyPair"

  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  tags = {
    Name        = "DevOps-Agent-Test"
    Environment = "test"
    Project     = "devops-agent"
  }
}

# Security group
resource "aws_security_group" "devops_sg" {
  name        = "devops-agent-test-sg"
  description = "Security group for DevOps Agent test server"
  vpc_id      = "vpc-64c6c703"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS MCP Servers"
    from_port   = 4431
    to_port     = 4432
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-agent-test-sg"
  }
}

output "instance_public_ip" {
  value = aws_instance.devops_server.public_ip
}

output "jenkins_url" {
  value = "http://${aws_instance.devops_server.public_ip}:8080"
}
