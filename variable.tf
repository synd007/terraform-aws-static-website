variable "region" {
  description = "The AWS region to deploy resources in"
  type        = string
  default     = "us-east-1"
}
variable "s3_bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "syndbucketteststaging"
}
variable "index_document" {
  description = "The name of the index document"
  type        = string
  default     = "index.html"
}

variable "error_document" {
  description = "The name of the error document"
  type        = string
  default     = "error.html"
}
variable "aws_s3_bucket_key" {
  description = "The key for the S3 object"
  type        = string
  default     = "index.html"
}
variable "aws_s3_bucket_source" {
  description = "The source file for the S3 object"
  type        = string
  default     = "index.html"
}


variable "aws_route53_zone" {
  description = "The Route 53 hosted zone"
  type        = string
  default     = "xsyndpessimist.cc"
}