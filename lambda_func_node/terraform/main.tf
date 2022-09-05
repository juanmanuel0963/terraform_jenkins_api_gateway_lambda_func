#############################################################################
# VARIABLES
#############################################################################

variable "region" {
  type    = string
}
/*
variable "access_key" {
  type    = string
}

variable "secret_key" {
  type    = string
}
*/
/*
variable "parent_api_gateway_id"{
  type    = string
}

variable "parent_api_gateway_name"{
  type    = string
}

variable "parent_api_gateway_execution_arn"{
  type    = string
}

variable "parent_api_gateway_invoke_url"{
  type    = string
}
*/
variable "lambda_func_name" {
  type    = string
}

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

resource "random_pet" "lambda_func_bucket_name" {
  prefix = "${replace("${var.lambda_func_name}", "_", "-")}-bucket"
  length = 1
}

  //lambda_func_bucket_name = random_pet.lambda_func_bucket_name.id
  //lambda_func_bucket_name = "${replace("${var.lambda_func_name}", "_", "-")}-bucket-${terraform.workspace}"

locals {
  lambda_func_bucket_name = "${replace("${var.lambda_func_name}", "_", "-")}-bucket-${random_integer.rand.result}"
  lambda_func_role_name = "${var.lambda_func_name}-role-${random_integer.rand.result}"
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
# MODULES
#############################################################################  

module "s3-bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.4.0"
}

#############################################################################
# RESOURCES
#############################################################################  

//----------S3 bucket creation----------

resource "aws_s3_bucket" "lambda_func_bucket" {    
  bucket = local.lambda_func_bucket_name  
  force_destroy = true
  provider = aws
  
  tags = {
    Environment = terraform.workspace
  }
}

//----------Zip file creation----------

//This configuration uses the archive_file data source to generate a zip archive 
//and an aws_s3_object resource to upload the archive to your S3 bucket.
data "archive_file" "the_lambda_function" {
  type = "zip"
  
  //----------Enable if calling from function----------
  //source_dir  = "${path.cwd}/../source_code"  
  //output_path = "${path.cwd}/../last_deploy/${var.lambda_func_name}.zip"

  //----------Enable if calling from root main----------
  source_dir  = "${path.cwd}/lambda_func_node/source_code"  
  output_path = "${path.cwd}/lambda_func_node/last_deploy/${var.lambda_func_name}.zip"
}

//----------Zip file upload----------

resource "aws_s3_object" "the_lambda_function" {
  bucket = aws_s3_bucket.lambda_func_bucket.id

  key    = "${var.lambda_func_name}.zip"
  source = data.archive_file.the_lambda_function.output_path
  etag = filemd5(data.archive_file.the_lambda_function.output_path)
}

//----------Lambda function creation.---------- 
//----------S3 bucket assignment----------
//----------S3 object(source code zip file) assignment----------
//----------Source code hash assignment----------
//----------IAM role assignment----------

//Configures the Lambda function to use the bucket object containing your function code. 
//It also sets the runtime to NodeJS 12.x, and assigns the handler to the handler function defined in hello.js. 
//The source_code_hash attribute will change whenever you update the code contained in the archive, 
//which lets Lambda know that there is a new version of your code available. 
//Finally, the resource specifies a role which grants the function permission to access AWS services and resources in your account.
resource "aws_lambda_function" "the_lambda_function" {
  function_name = "${var.lambda_func_name}"

  s3_bucket = aws_s3_bucket.lambda_func_bucket.id
  s3_key    = aws_s3_object.the_lambda_function.key

  runtime = "nodejs12.x"
  handler = "${var.lambda_func_name}.handler"

  source_code_hash = data.archive_file.the_lambda_function.output_base64sha256

  role = aws_iam_role.lambda_exec.arn
}

//----------IAM Rol creation----------

//Defines an IAM role that allows Lambda to access resources in your AWS account.
resource "aws_iam_role" "lambda_exec" {
  name = "${local.lambda_func_role_name}"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

//----------Policy assignment to the IAM Rol----------

//Attaches a policy to the IAM role.
//AWSLambdaBasicExecutionRole is an AWS managed policy that allows your Lambda function to write to CloudWatch logs.
resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

//----------CloudWatch assignment to IAM Rol----------

//Defines a log group to store log messages from your Lambda function for 30 days. 
//By convention, Lambda stores logs in a group with the name /aws/lambda/<Function Name>.
resource "aws_cloudwatch_log_group" "the_lambda_function" {
  name = "/aws/lambda/${aws_lambda_function.the_lambda_function.function_name}"
  retention_in_days = 30
}
/*
//----------API Gateway - adding lambda function (Integrations part) ----------

//Configures the API Gateway to use your Lambda function.
resource "aws_apigatewayv2_integration" "the_lambda_function" {
  //api_id = aws_apigatewayv2_api.lambda.id
  api_id = var.parent_api_gateway_id

  integration_uri    = aws_lambda_function.the_lambda_function.invoke_arn
  integration_type   = "AWS_PROXY"
  integration_method = "POST"
}

//----------API Gateway - adding lambda function (Routes part) ----------

//Maps an HTTP request to a target, in this case your Lambda function. 
//In the example configuration, the route_key matches any GET request matching the path /hello. 
//A target matching integrations/<ID> maps to a Lambda integration with the given ID.
resource "aws_apigatewayv2_route" "the_lambda_function" {
  //api_id = aws_apigatewayv2_api.lambda.id
  api_id = var.parent_api_gateway_id

  route_key = "ANY /${var.lambda_func_name}"  
  target    = "integrations/${aws_apigatewayv2_integration.the_lambda_function.id}"
}

//----------API Gateway - adding permissions to invoke lambda function ----------

//Gives API Gateway permission to invoke your Lambda function.
resource "aws_lambda_permission" "api_gw" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.the_lambda_function.function_name
  principal     = "apigateway.amazonaws.com"

  //source_arn = "${aws_apigatewayv2_api.lambda.execution_arn}/*//*"
  source_arn = "${var.parent_api_gateway_execution_arn}/*//*"
  
}
*/
##################################################################################
# OUTPUT
##################################################################################

output "lambda_func_name" {
  description = "Name of the Lambda function."
  value = aws_lambda_function.the_lambda_function.function_name
}

output "lambda_func_bucket_name" {
  description = "Name of the S3 bucket used to store function code."
  value = aws_s3_bucket.lambda_func_bucket.id
}

output "lambda_func_role_name" {
  description = "Name of the rol"
  value = aws_iam_role.lambda_exec.name
}
/*
output "lambda_func_base_url" {
  description = "Base URL for API Gateway stage + function name"
  //value = "${aws_apigatewayv2_stage.lambda.invoke_url}${var.lambda_func_name}"
  value = "${var.parent_api_gateway_invoke_url}${var.lambda_func_name}"  
}
*/
