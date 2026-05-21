variable "aws_region" {
  default = "ap-south-1"
}

variable "cluster_name" {
  default = "WezvaTech-EKS-Demo"
  type    = string
}

variable "node_instance_type" {
    default = "t2.medium"
}

variable "eksversion" {
    default = "1.33"
}

variable "caversion" {
    default = "v1.33.0"
}
