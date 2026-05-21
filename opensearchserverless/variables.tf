
variable "aws_region" {
  description = "The AWS region to create things in."
  default     = "ap-south-1"
}

variable "collection_name" {
  description = "Name of the OpenSearch Serverless collection."
  default     = "wezvatech-collection"
}

variable "vpcid" {
  description = "VPC in which opensearch should be created"
  default = "vpc-0e53618e41f946146"
}

variable "subnetids" {
  description = "subnet ids"
  type        = list(string)
  default = ["subnet-034ae6bc268a8a248", "subnet-0d4876621a535c5f1", "subnet-06ae91a8b23fe0ce6"]
}


variable "security_groups" {
  description = "A list of security group IDs to associate"
  type        = list(string)
  default = ["sg-0a781bd43a7ce089e"]
}

