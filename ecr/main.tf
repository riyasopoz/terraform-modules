provider "aws" {
  region = "ap-south-1"
}

module "ecr_repositories" {
  source = "./modules"

  # Pass any number of repository names here
  repository_names = [
    "wezvatechledger",
    "wezvatechpayment",
    "wezvatechnotification"
  ]
  
  image_mutability = "MUTABLE"
}

