data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_acm_certificate" "hbh_cert" {
  domain   = "hellobaghub.it.com"
  statuses = ["ISSUED"]
  most_recent = true
}

data "aws_caller_identity" "current" {}

