#-----------------------------------------------------------------------------------------------
#   VPC Link Config
#-----------------------------------------------------------------------------------------------

# Create App Security group
resource "aws_security_group" "vpc_link" {
  name   = "${var.project_name}-vpc-link"
  vpc_id = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create the VPC Link configured with the ALB subnets.
resource "aws_apigatewayv2_vpc_link" "api_vpc_link" {
  name              = "${var.project_name}-api_vpc_link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids        = var.private_subnet_ids
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

# Create CloudWatch log group for API Gateway logs
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-logs"
  retention_in_days = 7
}

# Set a default stage with logging enabled
resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId        = "$context.requestId"
      ip               = "$context.identity.sourceIp"
      requestTime      = "$context.requestTime"
      httpMethod       = "$context.httpMethod"
      routeKey         = "$context.routeKey"
      status           = "$context.status"
      protocol         = "$context.protocol"
      responseLength   = "$context.responseLength"
    })
  }

  depends_on = [aws_apigatewayv2_api.api]
}

data "aws_lambda_function" "authorizer_lambda" {
  function_name = var.authorizer_lambda_name
}

# Grant API Gateway permission to invoke the Lambda Authorizer
resource "aws_lambda_permission" "api_authorizer_lambda" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = data.aws_lambda_function.authorizer_lambda.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.api.execution_arn}/*/*"
}

# Create authorizer pointing to Lambda
resource "aws_apigatewayv2_authorizer" "api_authorizer" {
  name                              = "${var.project_name}-authorizer-by-lambda"
  api_id                            = aws_apigatewayv2_api.api.id
  authorizer_uri                    = data.aws_lambda_function.authorizer_lambda.invoke_arn
  identity_sources                  = []
  authorizer_type                   = "REQUEST"
  authorizer_payload_format_version = "2.0"
  authorizer_result_ttl_in_seconds  = 0
  enable_simple_responses           = true
}

# ####################################### API FOOD #######################################################

# Search for the Load Balancer created by the K8s service for api-food microservice
data "aws_lb" "eks_api_food" {
  tags = {
    "kubernetes.io/service-name"                = "default/${var.lb_service_name_api_food}"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# Get the Listener of the Load Balancer created by this Load Balancer
data "aws_lb_listener" "eks_api_food" {
  load_balancer_arn = data.aws_lb.eks_api_food.arn
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

# API Gateway route with ANY method for the main service (/{proxy+})
resource "aws_apigatewayv2_route" "api_gateway_route_api_food" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /food/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api_integration_api_food.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_authorizer.id
  depends_on         = [aws_apigatewayv2_integration.api_integration_api_food]
}

# ####################################### API ORDER #######################################################

# Search for the Load Balancer created by the K8s service for api-order microservice
data "aws_lb" "eks_api_order" {
  tags = {
    "kubernetes.io/service-name"                = "default/${var.lb_service_name_api_order}"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# Get the Listener of the Load Balancer created by this Load Balancer
data "aws_lb_listener" "eks_api_order" {
  load_balancer_arn = data.aws_lb.eks_api_order.arn
  port              = var.lb_service_port_api_order
}

# Create the API Gateway HTTP_PROXY integration
resource "aws_apigatewayv2_integration" "api_integration_api_order" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = data.aws_lb_listener.eks_api_order.arn
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api_vpc_link.id
  payload_format_version = "1.0"
  depends_on = [
    aws_apigatewayv2_vpc_link.api_vpc_link,
    aws_apigatewayv2_api.api
  ]
}

# API Gateway route with ANY method for the main service (/{proxy+})
resource "aws_apigatewayv2_route" "api_gateway_route_api_order" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /order/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api_integration_api_order.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_authorizer.id
  depends_on         = [aws_apigatewayv2_integration.api_integration_api_order]
}


# ####################################### API PAYMENTS #######################################################

# Search for the Load Balancer created by the K8s service for api-payments microservice
data "aws_lb" "eks_api_payments" {
  tags = {
    "kubernetes.io/service-name"                = "default/${var.lb_service_name_api_payments}"
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# Get the Listener of the Load Balancer created by this Load Balancer
data "aws_lb_listener" "eks_api_payments" {
  load_balancer_arn = data.aws_lb.eks_api_payments.arn
  port              = var.lb_service_port_api_payments
}

# Create the API Gateway HTTP_PROXY integration
resource "aws_apigatewayv2_integration" "api_integration_api_payments" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = data.aws_lb_listener.eks_api_payments.arn
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api_vpc_link.id
  payload_format_version = "1.0"
  depends_on = [
    aws_apigatewayv2_vpc_link.api_vpc_link,
    aws_apigatewayv2_api.api
  ]
}

# API Gateway route with ANY method for the main service (/{proxy+})
resource "aws_apigatewayv2_route" "api_gateway_route_api_payments" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /payment/{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api_integration_api_payments.id}"
  authorization_type = "CUSTOM"
  authorizer_id      = aws_apigatewayv2_authorizer.api_authorizer.id
  depends_on         = [aws_apigatewayv2_integration.api_integration_api_payments]
}