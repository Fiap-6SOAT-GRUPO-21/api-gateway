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
  name               = "${var.project_name}-api_vpc_link"
  security_group_ids = [aws_security_group.vpc_link.id]
  subnet_ids         = var.private_subnet_ids
}


#-----------------------------------------------------------------------------------------------
#   API Gateway Config
#-----------------------------------------------------------------------------------------------

# Create the API Gateway HTTP endpoint
resource "aws_apigatewayv2_api" "api" {
  name          = "${var.project_name}-api-gateway"
  protocol_type = "HTTP"
}

# Set a default stage
resource "aws_apigatewayv2_stage" "api_gateway_stage" {
  api_id      = aws_apigatewayv2_api.api.id
  name        = "$default"
  auto_deploy = true
  depends_on  = [aws_apigatewayv2_api.api]
}

# Search for the Load Balancer created by the K8s service for api-food micorservice
data "aws_lb" "eks_api_food" {
  tags = {
    "kubernetes.io/service-name" = var.lb_service_name_api_food
    "kubernetes.io/cluster/${var.project_name}" = "owned"
  }
}

# Get the Listener of the Load Balancer created by this Load Balancer
data "aws_lb_listener" "eks_api_food" {
  load_balancer_arn = "${data.aws_lb.eks_api_food.arn}"
  port              = var.lb_service_port_api_food
}

# Create the API Gateway HTTP_PROXY integration between the created API and the private load balancer via the VPC Link.
resource "aws_apigatewayv2_integration" "api_integration_api_food" {
  api_id                 = aws_apigatewayv2_api.api.id
  integration_type       = "HTTP_PROXY"
  integration_uri        = data.aws_lb_listener.eks_api_food.arn
  integration_method     = "ANY"
  connection_type        = "VPC_LINK"
  connection_id          = aws_apigatewayv2_vpc_link.api_vpc_link.id
  payload_format_version = "1.0"
  depends_on = [aws_apigatewayv2_vpc_link.api_vpc_link,
    aws_apigatewayv2_api.api
  ]
}


# API Gateway route with ANY method
resource "aws_apigatewayv2_route" "api_gateway_route_api_food" {
  api_id             = aws_apigatewayv2_api.api.id
  route_key          = "ANY /{proxy+}"
  target             = "integrations/${aws_apigatewayv2_integration.api_integration_api_food.id}"
  authorization_type = "NONE"
  depends_on         = [aws_apigatewayv2_integration.api_integration_api_food]
}
