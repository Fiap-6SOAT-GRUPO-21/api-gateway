data "aws_ssm_parameter" "vpc_id" {
  name = "/techchallenge/eks/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/techchallenge/eks/private_subnet_ids"
}

module "api_gateway" {
  source                   = "./modules/api-gateway"
  project_name             = var.project_name
  authorizer_lambda_name   = "techchallenge-authorizer-lambda"
  lb_service_name_api_food = "api-food-service"
  lb_service_port_api_food = 88
  lb_service_name_api_order = "api-order-service"
  lb_service_port_api_order = 89
  lb_service_name_api_payments = "api-payments-service"
  lb_service_port_api_payments = 90
  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  private_subnet_ids       = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
}

resource "aws_ssm_parameter" "api_gateway_endpoint" {
  name  = "/techchallenge/api_gateway/endpoint"
  type  = "String"
  value = module.api_gateway.api_gateway_endpoint
}