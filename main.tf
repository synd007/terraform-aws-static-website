resource "aws_s3_bucket" "synd_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_website_configuration" "synd_bucket_website" {
  bucket = aws_s3_bucket.synd_bucket.id

  index_document {
    suffix = var.index_document
  }

  error_document {
    key = var.error_document
  }
}

resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.synd_bucket.id
  key    = var.aws_s3_bucket_key
  source = var.aws_s3_bucket_key
  etag = filemd5(var.aws_s3_bucket_source)
  content_type = "text/html"
}

resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.synd_bucket.id

  policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
        {
            Effect    = "Allow"
            Principal = {
                AWS = aws_cloudfront_origin_access_identity.cdn.iam_arn
            }
            Action    = "s3:GetObject"
            Resource  = "arn:aws:s3:::${aws_s3_bucket.synd_bucket.id}/*"
        }
        ]
    })

    depends_on = [aws_s3_bucket_public_access_block.synd_bucket_block]
}

resource "aws_s3_bucket_public_access_block" "synd_bucket_block" {
  bucket = aws_s3_bucket.synd_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


resource "aws_route53_zone" "main" {
name = var.aws_route53_zone
}

resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.main.id
  name    = "www"
    type    = "A"
 
  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
resource "aws_cloudfront_origin_access_identity" "cdn" {
  comment = "OAI for S3 static website"
}
resource "aws_cloudfront_distribution" "cdn" {
    depends_on = [aws_cloudfront_origin_access_identity.cdn]
  origin {
    domain_name = aws_s3_bucket.synd_bucket.bucket_regional_domain_name 
    origin_id   = "s3-Origin"

    s3_origin_config {
        origin_access_identity = aws_cloudfront_origin_access_identity.cdn.cloudfront_access_identity_path
    }
   }
  enabled = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id = "s3-Origin"
    allowed_methods = ["GET", "HEAD"]
    cached_methods = ["GET", "HEAD"]

    forwarded_values {
     query_string = false
     cookies {
     forward = "none"
    }
  }
    viewer_protocol_policy = "redirect-to-https"
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
    restrictions {
        geo_restriction {
        restriction_type = "none"
        }
    }
}
