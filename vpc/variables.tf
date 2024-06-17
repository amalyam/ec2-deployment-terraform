variable "region" {
  type        = string
  description = "The region where we are creating the VPC"
  default     = "us-east-2"
}

variable "cidr_block" {
  type        = string
  description = "Value of cidr block"
  default     = "10.0.0.0/24"
}
