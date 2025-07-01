resource "aws_s3_bucket" "website-s3-bucket" {
#   bucket = "edisonlim.ca"
  bucket = "edisonlim.ca"
}

# resource "aws_s3_bucket_policy" "allow-public-read" {
# #   bucket = aws_s3_bucket.website-s3-bucket.id
# #   policy = data.aws_iam_policy_document.allow-public-read.json

#   bucket = aws_s3_bucket.website-s3-bucket.id
#   policy = data.aws_iam_policy_document.allow-public-read.json
# }

data "aws_iam_policy_document" "allow-public-read" {
#   statement {
#     sid       = "AllowCloudFrontServicePrincipal"
#     effect    = "Allow"
#     resources = ["${aws_s3_bucket.website-s3-bucket.arn}/*"]
#     actions   = ["s3:GetObject"]

#     condition {
#       test     = "ArnLike"
#       variable = "AWS:SourceArn"
#       values   = [aws_cloudfront_distribution.website-distribution.arn]
#     }

#     principals {
#       type        = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }
#   }

#   statement {
#     sid       = "PublicReadGetObject"
#     effect    = "Allow"
#     resources = ["${aws_s3_bucket.website-s3-bucket.arn}/*"]
#     actions   = ["s3:GetObject"]

#     principals {
#       type        = "*"
#       identifiers = ["*"]
#     }
#   }

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

  statement {
    sid       = "PublicReadGetObject"
    effect    = "Allow"
    resources = ["${aws_s3_bucket.website-s3-bucket.arn}/*"]
    actions   = ["s3:GetObject"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_cloudfront_distribution" "website-distribution" {
#   origin {
#     domain_name = aws_s3_bucket.website-s3-bucket.bucket_regional_domain_name
#     origin_access_control_id = aws_cloudfront_origin_access_control.cloudfront-oac.id
#     origin_id = "s3-origin"
#   }

#   enabled = true
#   is_ipv6_enabled = true
#   default_root_object = "index.html"

#   aliases = ["edisonlim.ca"]

#   default_cache_behavior {
#     cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
#     allowed_methods = ["GET", "HEAD"]
#     cached_methods = ["GET", "HEAD"]
#     target_origin_id = aws_cloudfront_origin_access_control.cloudfront-oac.id

#     viewer_protocol_policy = "redirect-to-https"
#   }

#   price_class = "PriceClass_All"

#   restrictions {
#     geo_restriction {
#       restriction_type = "none"
#       locations = []
#     }
#   }

#   viewer_certificate {
#     acm_certificate_arn = "arn:aws:acm:us-east-1:415730361496:certificate/d4a9d33a-d78d-43ea-bf35-de2fe36a904d"
#   }

  origin {
    domain_name = aws_s3_bucket.website-s3-bucket.bucket_regional_domain_name
    origin_access_control_id = "E3BOXF50GZX3SI"
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
#   name = "E3BOXF50GZX3SI"
#   description = "OAC for CloudFront to access S3 bucket"
#   origin_access_control_origin_type = "s3"
#   signing_behavior = "always"
#   signing_protocol = "sigv4"

  name = "oac-edisonlim.ca.s3.us-east-1.amazonaws.com-mc963ubl62h"
  description = "Created by CloudFront"
  origin_access_control_origin_type = "s3"
  signing_behavior = "always"
  signing_protocol = "sigv4"
}