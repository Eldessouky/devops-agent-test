variable "region" {
  default     = "eu-west-1"
  description = "AWS region"
}

variable "instance_type" {
  default     = "t3.medium"
  description = "EC2 instance type"
}

variable "key_name" {
  default     = "mnnashyKeyPair"
  description = "SSH key pair name"
}

variable "allowed_cidr" {
  default     = "0.0.0.0/0"
  description = "CIDR block allowed for SSH access"
}
