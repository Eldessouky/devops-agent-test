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
