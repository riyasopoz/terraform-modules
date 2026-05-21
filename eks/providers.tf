terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region = var.aws_region
}

provider "kubernetes" {
  alias = "eks"
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}
