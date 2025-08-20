## Terraform AWS Static Website Hosting

This project demonstrates how to host a static website on AWS using Terraform.

_It provisions and configures:_
1. Amazon S3 – to store the website files
2. CloudFront CDN – to securely distribute content with HTTPS
3. Route 53 – for custom domain DNS management
4. IAM Policies – to enforce secure access via Origin Access Identity (OAI)

### Features
- Fully automated setup with Infrastructure as Code (IaC)
- Secure S3 bucket with public access blocked
- HTTPS-enabled CloudFront distribution
- Custom domain integration via Route 53
- Example Terraform code with explanations

### Tech Stack
- Terraform
- AWS S3
- AWS CloudFront
- AWS Route 53
- IAM (OAI for CloudFront)

### Project Structure
_terraform-aws-static-website/_

│── _main.tf_                 _# Terraform infrastructure code_

│── _variables.tf_            _# Input variables_

│── _outputs.tf_              _# Outputs for reference_

│── _README.md_               _# Documentation (this file)_


### Author
John Eyo
