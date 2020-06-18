# AWS provider pointing at Localstack
provider "aws" {
	region  					= "us-east-1"
	access_key                  = "anaccesskey"
	secret_key                  = "asecretkey"
	s3_force_path_style 		= true
	skip_credentials_validation = true
  	skip_metadata_api_check     = true
  	skip_requesting_account_id  = true

	endpoints {
		ec2 	= "http://localhost:4566"
		s3  	= "http://localhost:4566"
		lambda  = "http://localhost:4566"
		iam     = "http://localhost:4566"
		apigateway = "http://localhost:4566"
	}	
}

resource "aws_s3_bucket" "komsomolec-lambda-bucket" {
	bucket = "komsomolec-lambda"
	acl    = "private"
	region = "us-east-1"

	tags = {
		Name = "komsomolec-lambda"
		Environment = "Dev"
	}
}

resource "aws_s3_bucket_object" "code" {
  depends_on = [aws_s3_bucket.komsomolec-lambda-bucket]
  bucket = "komsomolec-lambda"
  key    = "v1.1.2/lambda.zip"
  source = "lambda.zip"
  etag = "${filemd5("lambda.zip")}"
}

resource "aws_lambda_function" "function" {
	depends_on = [aws_s3_bucket_object.code]
	function_name = "PythonLambda"

	s3_bucket = "komsomolec-lambda"
	s3_key    = "v1.1.2/lambda.zip"

	handler = "lambda.lambda_handler"
	runtime = "python3.8"

	role = aws_iam_role.lambda_exec.arn
}

resource "aws_iam_role" "lambda_exec" {
	name = "lambda_role"

	assume_role_policy = <<EOF
	{
		"Version": "2012-10-17",
		"Statement": [
			{
				"Action": "sts:AssumeRole",
				"Principal": {
					"Service": "lambda.amazonaws.com"
				},
				"Effect": "Allow",
				"Sid": ""
			}
		]	
	}
	EOF
}

resource "aws_api_gateway_resource" "proxy" {
   rest_api_id = aws_api_gateway_rest_api.lambda_gateway.id
   parent_id   = aws_api_gateway_rest_api.lambda_gateway.root_resource_id
   path_part   = "{proxy+}"
}

resource "aws_api_gateway_method" "proxy" {
   rest_api_id   = aws_api_gateway_rest_api.lambda_gateway.id
   resource_id   = aws_api_gateway_resource.proxy.id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda" {
   rest_api_id = aws_api_gateway_rest_api.lambda_gateway.id
   resource_id = aws_api_gateway_method.proxy.resource_id
   http_method = aws_api_gateway_method.proxy.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_method" "proxy_root" {
   rest_api_id   = aws_api_gateway_rest_api.lambda_gateway.id
   resource_id   = aws_api_gateway_rest_api.lambda_gateway.root_resource_id
   http_method   = "ANY"
   authorization = "NONE"
}

resource "aws_api_gateway_integration" "lambda_root" {
   rest_api_id = aws_api_gateway_rest_api.lambda_gateway.id
   resource_id = aws_api_gateway_method.proxy_root.resource_id
   http_method = aws_api_gateway_method.proxy_root.http_method

   integration_http_method = "POST"
   type                    = "AWS_PROXY"
   uri                     = aws_lambda_function.function.invoke_arn
}

resource "aws_api_gateway_deployment" "lambda_gateway" {
   depends_on = [
     aws_api_gateway_integration.lambda,
     aws_api_gateway_integration.lambda_root,
   ]

   rest_api_id = aws_api_gateway_rest_api.lambda_gateway.id
   stage_name  = "test"
}

resource "aws_lambda_permission" "apigw" {
   statement_id  = "AllowAPIGatewayInvoke"
   action        = "lambda:InvokeFunction"
   function_name = aws_lambda_function.function.function_name
   principal     = "apigateway.amazonaws.com"

   # The "/*/*" portion grants access from any method on any resource
   # within the API Gateway REST API.
   source_arn = "${aws_api_gateway_rest_api.lambda_gateway.execution_arn}/*/*"
}

