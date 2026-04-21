provider "aws" {
  region = "eu-west-1"
}

# EC2 instance for Jenkins + GitHub Runner + MCP Servers
resource "aws_instance" "devops_server" {
  ami           = "ami-0442403fb8d244144"
  instance_type = "t3.large"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
    encrypted   = true
  }

  monitoring = true

  tags = {
    Name        = "DevOps-Agent-Test"
    Environment = "test"
    Project     = "devops-agent"
    ManagedBy   = "terraform"
  }
}

# CloudWatch alarm for high CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "devops-server-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when CPU exceeds 80%"

  dimensions = {
    InstanceId = aws_instance.devops_server.id
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
    cidr_blocks = [var.allowed_cidr]
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

# S3 bucket for Jenkins artifacts
resource "aws_s3_bucket" "jenkins_artifacts" {
  bucket = "devops-agent-jenkins-artifacts"

  tags = {
    Name      = "jenkins-artifacts"
    ManagedBy = "terraform"
  }
}
