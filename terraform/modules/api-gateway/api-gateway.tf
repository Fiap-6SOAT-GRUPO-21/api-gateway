#-----------------------------------------------------------------------------------------------
#   VPC Link Config
#-----------------------------------------------------------------------------------------------

# Create App Security group
resource "aws_security_group" "vpc_link" {
  name   = "${var.project_name}-vpc-link"
  vpc_id = var.vpc_id

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the VPC Link configured with the ALB subnets.
resource "aws_apigatewayv2_vpc_link" "api_vpc_link" {
  name       = "${var.project_name}-api_vpc_link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids = var.private_subnet_ids
}


#-----------------------------------------------------------------------------------------------
#   API Gateway Config
#-----------------------------------------------------------------------------------------------

# Create the API Gateway HTTP endpoint
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api-gateway"
  protocol_type = "HTTP"
}

data "aws_caller_identity" "current" {}


# Set a default stage with logging enabled
resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  depends_on = [aws_apigatewayv2_api.api]
}


data "aws_lambda_function" "authorizer_lambda" {
  function_name = var.authorizer_lambda_name
}

# Create authorizer pointing to Lambda
resource "aws_apigatewayv2_authorizer" "api_authorizer" {
  name                              = "${var.project_name}-authorizer-by-lambda"
  api_id                            = aws_apigatewayv2_api.api.id
  authorizer_uri                    = data.aws_lambda_function.authorizer_lambda.invoke_arn
  identity_sources = []
  authorizer_type                   = "REQUEST"
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = true
}

# Search for the Load Balancer created by the K8s service for api-food microservice
data "aws_lb" "eks_api_food" {
  tags = {
    "kubernetes.io/service-name"                = "default/${var.lb_service_name_api_food}"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# Get the Listener of the Load Balancer created by this Load Balancer
data "aws_lb_listener" "eks_api_food" {
  load_balancer_arn = "${data.aws_lb.eks_api_food.arn}"
  port              = var.lb_service_port_api_food
}

# Create the API Gateway HTTP_PROXY integration
resource "aws_apigatewayv2_integration" "api_integration_api_food" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = data.aws_lb_listener.eks_api_food.arn
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api_vpc_link.id
  payload_format_version = "1.0"
  depends_on = [
    aws_apigatewayv2_vpc_link.api_vpc_link,
    aws_apigatewayv2_api.api
  ]
}

# API Gateway route with ANY method for the main service
resource "aws_apigatewayv2_route" "api_gateway_route_api_food" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api_integration_api_food.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_authorizer.id
  depends_on = [aws_apigatewayv2_integration.api_integration_api_food]
}
