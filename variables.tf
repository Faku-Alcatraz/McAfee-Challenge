variable "region" {
  description = "The AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cooldown" {
  type        = number
  default     = 300
}

variable "healthcheck_grace_period" {
  type        = number
  default     = 300
}

variable "deregistration_delay" {
  type        = number
  default     = 300
}

variable "target_group_port" {
  type        = number
  default     = 80
}

variable "listener_port" {
  type        = string
  default     = "80"
}