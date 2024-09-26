variable "instance_type" {
  type = string
}

variable "secrets_path" {
  type = string
}

variable "database_name" {
  type = string
}

variable "subnets" {
  type = list(any)
}

variable "maintainer" {
  type = string
}

variable "region" {
  type = string
}

variable "project" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "multi_az" {
  type    = bool
  default = true
}

variable "encryption_enabled" {
  type    = bool
  default = false
}

variable "apply_immediately" {
  type    = bool
  default = false
}

variable "maintainance_window" {
  type    = string
  default = "Mon:00:00-Mon:03:00"
}

variable "backup_window" {
  type    = string
  default = "03:00-06:00"
}

variable "enabled_cloudwatch_logs_exports" {
  type    = list(string)
  default = ["error", "general", "slowquery", "audit"]
}

variable "backup_retention_period" {
  type    = number
  default = 15
}

variable "monitoring_interval" {
  type    = number
  default = 0
}

variable "performance_insights_enabled" {
  type    = bool
  default = false
}

variable "max_allocated_storage" {
  type    = number
  default = 120
}