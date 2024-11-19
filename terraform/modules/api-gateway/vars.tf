variable "project_name" {
  description = "The name of the project"
  type = string
}

variable vpc_id {
  description = "VPC ID from which belogs the subnets"
  type        = string
}

variable "private_subnet_ids" {
  type = list(string)
  description = "List of subnet IDs."
}

variable "lb_service_name_api_food" {
  type = string
  description = "Name of the Load Balancer K8s service that exposes the orders microservices (api-food)"
}

variable "lb_service_port_api_food" {
  type = number
  description = "Port exposed of the Load Balancer K8s service associated to the orders microservices"
}

variable "lb_service_name_api_order" {
  type = string
  description = "Name of the Load Balancer K8s service that exposes the orders microservices (api-order)"
}

variable "lb_service_port_api_order" {
  type = number
  description = "Port exposed of the Load Balancer K8s service associated to the orders microservices (api-order)"
}

variable "lb_service_name_api_payments" {
  type = string
  description = "Name of the Load Balancer K8s service that exposes the orders microservices (api-payments)"
}

variable "lb_service_port_api_payments" {
  type = number
  description = "Port exposed of the Load Balancer K8s service associated to the orders microservices (api-payments)"
}

variable "authorizer_lambda_name" {
    type = string
    description = "Name of the Lambda function that will be used as authorizer"
}