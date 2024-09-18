variable "region" {
  description = "AWS region to deploy to"
  default     = "us-east-1"
  type        = string
}

variable "project_name" {
  type    = string
  default = "techchallenge"
}