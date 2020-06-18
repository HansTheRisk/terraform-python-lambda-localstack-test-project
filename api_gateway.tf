resource "aws_api_gateway_rest_api" "lambda_gateway" {
	name = "LambdaGateway"
	description = "Lambda API Gateway"
}

output "base_url" {
  value = aws_api_gateway_deployment.lambda_gateway.invoke_url
}