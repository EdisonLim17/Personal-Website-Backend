resource "aws_s3_bucket" "website-s3-bucket" {
  bucket = "edisonlim.ca"
}

resource "aws_s3_bucket_policy" "allow-public-read" {
  bucket = aws_s3_bucket.website-s3-bucket.id
  policy = data.aws_iam_policy_document.allow-public-read.json
}

data "aws_iam_policy_document" "allow-public-read" {
  statement {
    sid       = "AllowCloudFrontServicePrincipal"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.website-s3-bucket.arn}/*"]
    actions   = ["s3:GetObject"]

    condition {
      test     = "ArnLike"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.website-distribution.arn]
    }

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }
  }
}

resource "aws_cloudfront_distribution" "website-distribution" {
  origin {
    domain_name = aws_s3_bucket.website-s3-bucket.bucket_regional_domain_name
    origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront-oac.id
    origin_id = "edisonlim.ca.s3.us-east-1.amazonaws.com-mc963onjevv"
  }

  tags = {  
    Name = "PersonalWebsiteDistribution"
  }

  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  aliases = ["edisonlim.ca"]

  default_cache_behavior {
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]
    target_origin_id = "edisonlim.ca.s3.us-east-1.amazonaws.com-mc963onjevv"
    compress = true

    viewer_protocol_policy = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations = []
    }
  }

  viewer_certificate {
    acm_certificate_arn = "arn:aws:acm:us-east-1:415730361496:certificate/d4a9d33a-d78d-43ea-bf35-de2fe36a904d"
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method = "sni-only"
  }
}

resource "aws_cloudfront_origin_access_control" "cloudfront-oac" {
  name = "oac-edisonlim.ca.s3.us-east-1.amazonaws.com-mc963ubl62h"
  description = "Created by CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}

resource "aws_dynamodb_table" "website-dynamodb-table" {
  name = "VisitorCount"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "id" # Primary key for the table
  attribute {
    name = "id"
    type = "S" # String type for the primary key
  }
}

resource "aws_lambda_function" "get-visitor-count-function" {
  filename = data.archive_file.get-visitor-count-zip.output_path
  function_name = "GetWebsiteVisitorCount"
  role = aws_iam_role.lambda-exec-role.arn
  handler = "getwebsitevisitorcount.lambda_handler"
  runtime = "python3.13"
}

resource "aws_lambda_function" "update-visitor-count-function" {
  filename = data.archive_file.update-visitor-count-zip.output_path
  function_name = "UpdateWebsiteVisitorCount"
  role = aws_iam_role.lambda-exec-role.arn
  handler = "updatewebsitevisitorcount.lambda_handler"
  runtime = "python3.11"
}

data "archive_file" "get-visitor-count-zip" {
  type = "zip"
  source_file = "${path.module}/lambda/getwebsitevisitorcount.py"
  output_path = "${path.module}/lambda/GetWebsiteVisitorCount.zip"
}

data "archive_file" "update-visitor-count-zip" {
  type = "zip"
  source_file = "${path.module}/lambda/updatewebsitevisitorcount.py"
  output_path = "${path.module}/lambda/UpdateWebsiteVisitorCount.zip"
}

resource "aws_iam_role" "lambda-exec-role" {
  name = "LambdaRoleForDynamoDB"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
  description = "Allows Lambda functions to read and write to DynamoDB."
}

resource "aws_iam_policy" "dynamodb-read-write-policy" {
  name = "DynamoDBReadWrite"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "ReadWriteTable"
        Effect = "Allow"
        Action = [
          "dynamodb:BatchGetItem",
          "dynamodb:GetItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:BatchWriteItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem"
        ]
        Resource = aws_dynamodb_table.website-dynamodb-table.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda-dynamodb-policy" {
  role = aws_iam_role.lambda-exec-role.id
  policy_arn = aws_iam_policy.dynamodb-read-write-policy.arn
}

resource "aws_lambda_permission" "allow-api-gateway-get" {
  statement_id = "167c023e-204e-533b-b813-20a4411b50b6"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get-visitor-count-function.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.website-to-lambda-api.execution_arn}/*/GET/websitecounterlambdaendpoint"
}

resource "aws_lambda_permission" "allow-api-gateway-post" {
  statement_id = "8d76a1cf-b19f-5cce-b57c-3a870b8d1dfc"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.update-visitor-count-function.function_name
  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.website-to-lambda-api.execution_arn}/*/POST/websitecounterlambdaendpoint"
  
}

resource "aws_api_gateway_rest_api" "website-to-lambda-api" {
  name = "websitecounter2"
  description = "API for the personal website to get and update visitor count."
}

resource "aws_api_gateway_resource" "visitor-count-resource" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  parent_id = aws_api_gateway_rest_api.website-to-lambda-api.root_resource_id
  path_part = "websitecounterlambdaendpoint"
}

resource "aws_api_gateway_method" "website-to-lambda-api-GET" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "website-to-lambda-api-POST" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_method" "website-to-lambda-api-OPTIONS" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "website-to-lambda-api-GET" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = aws_api_gateway_method.website-to-lambda-api-GET.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.get-visitor-count-function.invoke_arn
  content_handling = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_integration" "website-to-lambda-api-POST" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = aws_api_gateway_method.website-to-lambda-api-POST.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri = aws_lambda_function.update-visitor-count-function.invoke_arn
  content_handling = "CONVERT_TO_TEXT"
}

resource "aws_api_gateway_integration" "website-to-lambda-api-OPTIONS" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = aws_api_gateway_method.website-to-lambda-api-OPTIONS.http_method
  type = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "website-to-lambda-api-OPTIONS" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = aws_api_gateway_method.website-to-lambda-api-OPTIONS.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false,
    "method.response.header.Access-Control-Allow-Methods" = false,
    "method.response.header.Access-Control-Allow-Origin"  = false
  }
}

resource "aws_api_gateway_integration_response" "website-to-lambda-api-OPTIONS" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  resource_id = aws_api_gateway_resource.visitor-count-resource.id
  http_method = aws_api_gateway_method.website-to-lambda-api-OPTIONS.http_method
  status_code = aws_api_gateway_method_response.website-to-lambda-api-OPTIONS.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT'",
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }
}

resource "aws_api_gateway_deployment" "website-to-lambda-api-deployment" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  description  = "prod"

  depends_on = [
    aws_api_gateway_method.website-to-lambda-api-GET,
    aws_api_gateway_method.website-to-lambda-api-POST,
    aws_api_gateway_method.website-to-lambda-api-OPTIONS,
    aws_api_gateway_integration.website-to-lambda-api-GET,
    aws_api_gateway_integration.website-to-lambda-api-POST,
    aws_api_gateway_integration.website-to-lambda-api-OPTIONS
  ]
}

resource "aws_api_gateway_stage" "prod" {
  rest_api_id = aws_api_gateway_rest_api.website-to-lambda-api.id
  deployment_id = aws_api_gateway_deployment.website-to-lambda-api-deployment.id
  stage_name = "prod"
}
