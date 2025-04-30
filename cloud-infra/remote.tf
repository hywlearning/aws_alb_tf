# Using a single workspace:
terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "terraform-hyw"

    workspaces {
      name = "aws_alb_tf"
    }
  }
}
