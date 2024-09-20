data "aws_ssm_parameter" "vpc_id" {
  name = "/techchallenge/eks/vpc_id"
}

data "aws_ssm_parameter" "private_subnet_ids" {
  name = "/techchallenge/eks/private_subnet_ids"
}

module "api_gateway" {
  source                   = "./modules/api-gateway"
  project_name             = var.project_name
  lb_service_name_api_food = "api-food-service"
  authorizer_lambda_name   = "techchallenge-authorizer-lambda"
  region                   = var.region
  lb_service_port_api_food = 80
  vpc_id                   = data.aws_ssm_parameter.vpc_id.value
  private_subnet_ids = split(",", data.aws_ssm_parameter.private_subnet_ids.value)
}

resource "aws_ssm_parameter" "api_gateway_endpoint" {
  name  = "/techchallenge/api_gateway/endpoint"
  type  = "String"
  value = module.api_gateway.api_gateway_endpoint
}