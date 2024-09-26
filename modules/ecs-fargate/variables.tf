variable "api_image" {
  type        = string
  description = "Image to pull from ECR"
}

variable "fp_enabled" {
  type        = bool
  description = "Feature Preview enabled in environment"
  default     = false
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC to deploy the cluster"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR range of the VPC"
}

variable "maintainer" {
  type        = string
  description = "Maintainer developer or automation tool"
}

variable "project" {
  type        = string
  description = "Name of the project"
}

variable "region" {
  type        = string
  description = "Region"
}

variable "app_domain_name" {
  type        = string
  description = "CNAME for the application"
}

variable "public_subnets" {
  type        = list(any)
  description = "List of public subnets to use"
}

variable "private_subnets" {
  type        = list(any)
  description = "List of private subnets to use"
}

variable "environment" {
  type        = string
  description = "Environment for the application"
}

variable "backend_variables" {
  type        = map(string)
  default     = {}
  description = "Backend variables as a map(string) that will be pushed as environment variables"
}

variable "backend_secrets" {
  type        = list(string)
  default     = []
  description = "List of backend secrets that will be read from Secrets Manager per environment and application"
}

variable "container_port_backend" {
  type        = string
  description = "Backend Application port"
}

variable "container_port_api" {
  type        = string
  description = "Backend Application port"
}

variable "http_redirect" {
  description = "HTTP-HTTPS redirection enabled"
  default     = true
}

variable "secrets_global" {
  type        = list(string)
  default     = []
  description = "List of backend global secrets that will be read from Secrets Manager"
}

variable "health_check_path" {
  type        = string
  default     = "/"
  description = "Default URL test"
}

variable "api_task_cpu" {
  type        = string
  default     = "1024"
  description = "CPU spec for backend app"
}

variable "api_task_ram" {
  type        = string
  default     = "4096"
  description = "RAM spec for backend app"
}

variable "desired_count_backend" {
  type        = number
  default     = 1
  description = "Default number of tasks in service"
}


variable "environment_secrets" {
  description = "List of environment-specific secrets"
  type        = list(string)
  default     = []
}