#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

resource "aws_iam_role" "demo-node" {
  name = "wezvatech-eks-demo-node"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.demo-node.name
}

resource "aws_iam_role_policy_attachment" "demo-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.demo-node.name
}

data "aws_ssm_parameter" "eks_ami_id" {
  name = "/aws/service/eks/optimized-ami/${var.eksversion}/amazon-linux-2023/x86_64/standard/recommended/image_id"
}

# Creating Launch Template for Worker Nodes
resource "aws_launch_template" "worker-node-launch-template" {
  name = "eks-worker-node-launch-template"
  block_device_mappings {
    device_name = "/dev/sdf"

    ebs {
      volume_size = 20
    }
  }

  #image_id      = data.aws_ami.eks_worker.id
  image_id      = data.aws_ssm_parameter.eks_ami_id.value
  instance_type = var.node_instance_type
  update_default_version = true

  vpc_security_group_ids = [
    aws_security_group.demo-cluster.id,          # Your custom SG
    aws_eks_cluster.demo.vpc_config[0].cluster_security_group_id # The EKS created SG
  ]

user_data = base64encode(<<-EOT
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary="BOUNDARY"

--BOUNDARY
Content-Type: application/node.eks.aws

---
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: ${var.cluster_name}
    apiServerEndpoint: ${aws_eks_cluster.demo.endpoint}
    certificateAuthority: ${aws_eks_cluster.demo.certificate_authority[0].data}
    cidr: ${aws_eks_cluster.demo.kubernetes_network_config[0].service_ipv4_cidr}

--BOUNDARY--
EOT
)


  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "EKS-Worker-Nodes"
    }
  }

  lifecycle {
   create_before_destroy = true
  }
  
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # AL2023 requires IMDSv2
    http_put_response_hop_limit = 2          # Critical: Must be at least 2
  }
}

#data "aws_ami" "eks_worker" {
#  most_recent = true
#  owners = [data.aws_caller_identity.current.account_id]
#  
#  filter {
#     name = "name"
#     values = ["amazon-eks-node-${var.eksversion}-v*"]
#  }
#}

resource "aws_eks_node_group" "demo" {
  cluster_name    = aws_eks_cluster.demo.name
  node_group_name = "demo"
  node_role_arn   = aws_iam_role.demo-node.arn
  subnet_ids      = aws_subnet.demo[*].id

  scaling_config {
    desired_size = 1
    max_size     = 6
    min_size     = 1
  }

  launch_template {
    id = aws_launch_template.worker-node-launch-template.id
    version = "$Latest"
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.demo-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.demo-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.demo-node-AmazonEC2ContainerRegistryReadOnly,
  ]
  
  tags = {
    "Name" = "EKS-demo-nodegroup"
  }
}
