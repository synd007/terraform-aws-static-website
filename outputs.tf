
output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cdn.domain_name
}
output "route53_nameservers" {
  description = "Nameservers to set in GoDaddy"
  value       = aws_route53_zone.main.name_servers
}
