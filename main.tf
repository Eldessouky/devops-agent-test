provider "aws" {
  region = "eu-west-1"
}

# EC2 instance for Jenkins + GitHub Runner + MCP Servers
resource "aws_instance" "devops_server" {
  ami           = "ami-0442403fb8d244144"
  instance_type = "r6i.2xlarge"
  key_name      = var.key_name

  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_size = 500
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

resource "aws_s3_bucket_versioning" "jenkins_artifacts" {
  bucket = aws_s3_bucket.jenkins_artifacts.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_rds_cluster" "analytics" {
  cluster_identifier = "analytics-cluster"
  engine             = "aurora-postgresql"
  engine_version     = "15.4"
  master_username    = "admin"
  master_password    = "changeme123"
  database_name      = "analytics"
  skip_final_snapshot = true

  tags = {
    Name      = "analytics-db"
    ManagedBy = "terraform"
  }
}

resource "aws_security_group" "rds_sg" {
  name        = "analytics-rds-sg"
  description = "Security group for Aurora analytics cluster"
  vpc_id      = "vpc-64c6c703"

  ingress {
    description = "PostgreSQL from VPC"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["172.31.0.0/16"]
  }

  ingress {
    description = "PostgreSQL from anywhere"
    from_port   = 5432
    to_port     = 5432
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

resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = "subnet-663c032f"

  tags = {
    Name = "devops-nat-gateway"
  }
}

resource "aws_lb" "app" {
  name               = "devops-app-lb"
  internal           = false
  load_balancer_type = "application"
  subnets            = ["subnet-663c032f", "subnet-24e7cd43"]

  tags = {
    Name = "devops-alb"
  }
}

resource "aws_rds_cluster_instance" "analytics" {
  count              = 3
  identifier         = "analytics-${count.index}"
  cluster_identifier = aws_rds_cluster.analytics.id
  instance_class     = "db.r6g.2xlarge"
  engine             = aws_rds_cluster.analytics.engine
}
