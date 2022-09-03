#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type    = string
}

variable "access_key" {
  type    = string
}

variable "secret_key" {
  type    = string
}

variable "api_gateway_name" {
  type    = string
}

#############################################################################
# PROVIDERS
#############################################################################

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.27"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.3.2"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
  }
}

provider "aws" {
  region = var.region
  //access_key = var.access_key
  //secret_key = var.secret_key
}

#############################################################################
# RESOURCES
#############################################################################  

//----------API Gateway creation----------

//Defines a name for the API Gateway and sets its protocol to HTTP.
resource "aws_apigatewayv2_api" "lambda" {
  name          = var.api_gateway_name
  protocol_type = "HTTP"
}

//----------API Gateway default stage creation----------

//Sets up application stages for the API Gateway - such as "Test", "Staging", and "Production". 
//The example configuration defines a single stage, with access logging enabled.
resource "aws_apigatewayv2_stage" "lambda" {
  api_id = aws_apigatewayv2_api.lambda.id

  name = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw.arn

    format = jsonencode({
      requestId               = "$context.requestId"
      sourceIp                = "$context.identity.sourceIp"
      requestTime             = "$context.requestTime"
      protocol                = "$context.protocol"
      httpMethod              = "$context.httpMethod"
      resourcePath            = "$context.resourcePath"
      routeKey                = "$context.routeKey"
      status                  = "$context.status"
      responseLength          = "$context.responseLength"
      integrationErrorMessage = "$context.integrationErrorMessage"
      }
    )
  }
}


//----------API Gateway - adding Cloud Watch ----------

//Defines a log group to store access logs for the aws_apigatewayv2_stage.lambda API Gateway stage.
resource "aws_cloudwatch_log_group" "api_gw" {
  name = "/aws/api_gw/${aws_apigatewayv2_api.lambda.name}"

  retention_in_days = 30
}

##################################################################################
# OUTPUT
##################################################################################

output "api_gateway_id" {
  description = "Id of the API Gateway."
  value = aws_apigatewayv2_api.lambda.id
}

output "api_gateway_name" {
  description = "Name of the API Gateway."
  value = aws_apigatewayv2_api.lambda.name
}

output "api_gateway_execution_arn" {
  description = "Execution arn of the API Gateway."
  value = aws_apigatewayv2_api.lambda.execution_arn
}

output "api_gateway_invoke_url" {
  description = "Base URL for API Gateway stage."
  value = "${aws_apigatewayv2_stage.lambda.invoke_url}"
}