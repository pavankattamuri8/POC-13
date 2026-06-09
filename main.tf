provider "aws" {
  region = "us-east-1"
}

############################
# 1. EKS Cluster (Control Plane)
############################
resource "aws_eks_cluster" "poc" {
  name     = "poc-cluster"
  role_arn = "arn:aws:iam::860801567613:role/instanceRoleforpoc13"

  vpc_config {
    subnet_ids = [
    
  "subnet-0f91618dbecad7449",
  "subnet-0b2c0c8a0af402202",
  "subnet-07c0ef75bcc4e0f9b"
]

  }
}

############################
# 2. IAM Role for Worker Nodes (FIX)
############################
resource "aws_iam_role" "eks_node_role" {
  name = "eks-node-role-poc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

############################
# 3. Attach Required Policies to Node Role
############################
resource "aws_iam_role_policy_attachment" "eks_worker_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ecr_readonly_policy" {
  role       = aws_iam_role.eks_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

############################
# 4. Node Group (Worker Nodes)
############################
resource "aws_eks_node_group" "poc_nodes" {
  cluster_name    = aws_eks_cluster.poc.name
  node_group_name = "poc-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    "subnet-0d2c14c66f6530651",
    "subnet-03dd3ff00040da7ff",
    "subnet-04816d32cf91f4879"
  ]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["c7i-flex.large"]

  depends_on = [
    aws_eks_cluster.poc,
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly_policy
  ]
}
