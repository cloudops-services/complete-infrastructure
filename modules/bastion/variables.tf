variable "environment" {
  type = string
}

variable "project" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "public_subnets" {
  type        = list(any)
  description = "List of public subnets to use"
}