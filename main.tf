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

##################################################################################
# api_gateway
##################################################################################

module "module_api_gateway" {
    source = "./api_gateway/terraform"
    region = var.region  
    access_key = var.access_key 
    secret_key = var.secret_key
    api_gateway_name = "API_Gateway_lambda_functions"
}

##################################################################################
# api_gateway - OUTPUT
##################################################################################

output "module_api_gateway_id" {
  description = "Id of the API Gateway."
  value = module.module_api_gateway.api_gateway_id
}

output "module_api_gateway_name" {
  description = "Name of the API Gateway."
  value = module.module_api_gateway.api_gateway_name
}

output "module_api_gateway_execution_arn" {
  description = "Execution arn of the API Gateway."
  value = module.module_api_gateway.api_gateway_execution_arn
}

output "module_api_gateway_invoke_url" {
  description = "Base URL for API Gateway stage."
  value = module.module_api_gateway.api_gateway_invoke_url
}

##################################################################################
# lambda_func_node
##################################################################################
/*
module "module_lambda_func_node" {
    source = "./lambda_func_node/terraform"
    region = var.region  
    access_key = var.access_key 
    secret_key = var.secret_key
    lambda_func_name = "lambda_func_node"
    parent_api_gateway_id = module.module_api_gateway.api_gateway_id
    parent_api_gateway_name = module.module_api_gateway.api_gateway_name
    parent_api_gateway_execution_arn = module.module_api_gateway.api_gateway_execution_arn
    parent_api_gateway_invoke_url = module.module_api_gateway.api_gateway_invoke_url
    
}

############################################################################  ######
# lambda_func_node - OUTPUT
##################################################################################

output "module_lambda_func_node_lambda_func_name" {
  description = "Name of the Lambda function."
  value = module.module_lambda_func_node.lambda_func_name
}

output "module_lambda_func_node_lambda_func_bucket_name" {
  description = "Name of the S3 bucket used to store function code."
  value = module.module_lambda_func_node.lambda_func_bucket_name
}

output "module_lambda_func_node_lambda_func_role_name" {
  description = "Name of the rol"
  value = module.module_lambda_func_node.lambda_func_role_name
}

output "module_lambda_func_node_lambda_func_base_url" {
  description = "Base URL for API Gateway stage + function name"
  value = module.module_lambda_func_node.lambda_func_base_url
}

##################################################################################
# lambda_func_go
##################################################################################

module "module_lambda_func_go" {
    source = "./lambda_func_go/terraform"
    region = var.region  
    access_key = var.access_key 
    secret_key = var.secret_key
    lambda_func_name = "lambda_func_go"
    parent_api_gateway_id = module.module_api_gateway.api_gateway_id
    parent_api_gateway_name = module.module_api_gateway.api_gateway_name
    parent_api_gateway_execution_arn = module.module_api_gateway.api_gateway_execution_arn
    parent_api_gateway_invoke_url = module.module_api_gateway.api_gateway_invoke_url    
    
}

##################################################################################
# lambda_func_go - OUTPUT
##################################################################################

output "module_lambda_func_go_lambda_func_name" {
  description = "Name of the Lambda function."
  value = module.module_lambda_func_go.lambda_func_name
}

output "module_lambda_func_go_lambda_func_bucket_name" {
  description = "Name of the S3 bucket used to store function code."
  value = module.module_lambda_func_go.lambda_func_bucket_name
}

output "module_lambda_func_go_lambda_func_role_name" {
  description = "Name of the rol"
  value = module.module_lambda_func_go.lambda_func_role_name
}

output "module_lambda_func_go_lambda_func_base_url" {
  description = "Base URL for API Gateway stage + function name"
  value = module.module_lambda_func_go.lambda_func_base_url
}
*/