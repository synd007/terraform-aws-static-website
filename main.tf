# Create S3 Bucket for Website Hosting
resource "aws_s3_bucket" "synd_bucket" {
  bucket = var.s3_bucket_name   # Name of the S3 bucket, pulled from variables
}

# Configure S3 Bucket for Website Hosting
resource "aws_s3_bucket_website_configuration" "synd_bucket_website" {
  bucket = aws_s3_bucket.synd_bucket.id   # Use the ID of the created S3 bucket

  index_document {
    suffix = var.index_document           # File to serve as index page
  }

  error_document {
    key = var.error_document              # File to serve as error page 
  }
}


# Upload Website Files to S3 Bucket
resource "aws_s3_object" "object" {
  bucket = aws_s3_bucket.synd_bucket.id   # Target bucket where the file will be uploaded
  key    = var.aws_s3_bucket_key          # The object key (name inside the bucket)
  source = var.aws_s3_bucket_key          # Local path of the file to upload
  etag   = filemd5(var.aws_s3_bucket_source) # Hash for file integrity check
  content_type = "text/html"              # Set MIME type to HTML
}

# S3 Bucket Policy (allow CloudFront access only)
resource "aws_s3_bucket_policy" "static_site_policy" {
  bucket = aws_s3_bucket.synd_bucket.id   # Apply policy to this S3 bucket

  # Define IAM policy in JSON format
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"   # Allow permission
        Principal = {
          AWS = aws_cloudfront_origin_access_identity.cdn.iam_arn # Allow only CloudFront OAI
        }
        Action    = "s3:GetObject" # Allow CloudFront to read files from S3
        Resource  = "arn:aws:s3:::${aws_s3_bucket.synd_bucket.id}/*" # All objects inside bucket
      }
    ]
  })

  depends_on = [aws_s3_bucket_public_access_block.synd_bucket_block] # Wait for block public access
}


# Block Public Access to S3 (force security)
resource "aws_s3_bucket_public_access_block" "synd_bucket_block" {
  bucket = aws_s3_bucket.synd_bucket.id

  block_public_acls       = true  # Block public ACLs
  block_public_policy     = true  # Block public bucket policies
  ignore_public_acls      = true  # Ignore any public ACLs applied
  restrict_public_buckets = true  # Fully restrict public access
}


# Route 53 Hosted Zone (Domain DNS Zone)
resource "aws_route53_zone" "main" {
  name = var.aws_route53_zone  # Custom domain name 
}

# Route 53 DNS Record (point domain to CloudFront)
resource "aws_route53_record" "website" {
  zone_id = aws_route53_zone.main.id # Use the hosted zone created
  name    = "www"                    # Subdomain 
  type    = "A"                      # Alias record type

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name   # CloudFront domain name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id # CloudFront hosted zone
    evaluate_target_health = false  # Don’t check health before routing
  }
}

# CloudFront Origin Access Identity (OAI). Used to securely allow CloudFront to fetch S3 content
resource "aws_cloudfront_origin_access_identity" "cdn" {
  comment = "OAI for S3 static website"
}


# CloudFront Distribution (CDN)
resource "aws_cloudfront_distribution" "cdn" {
  depends_on = [aws_cloudfront_origin_access_identity.cdn] # Ensure OAI is created first

  origin {
    domain_name = aws_s3_bucket.synd_bucket.bucket_regional_domain_name  # S3 bucket domain name
    origin_id   = "s3-Origin"                                           # Unique ID for this origin

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.cdn.cloudfront_access_identity_path
      # Attach the OAI to restrict direct S3 access
    }
  }

  enabled = true                   # Enable the distribution
  default_root_object = "index.html" # Default page to serve


  # Default Cache Behavior
  default_cache_behavior {
    target_origin_id = "s3-Origin"   # Use the S3 bucket as origin
    allowed_methods  = ["GET", "HEAD"] # Allowed HTTP methods
    cached_methods   = ["GET", "HEAD"] # Cache only safe methods

    forwarded_values {
      query_string = false # Don’t forward query strings
      cookies {
        forward = "none"   # Don’t forward cookies
      }
    }
    viewer_protocol_policy = "redirect-to-https" # Force HTTPS
  }
  # SSL/TLS Certificate
  viewer_certificate {
    cloudfront_default_certificate = true # Use default *.cloudfront.net SSL certificate
  }
  # Restrictions (Geo Restrictions)
  restrictions {
    geo_restriction {
      restriction_type = "none" # No geo-blocking
    }
  }
}
