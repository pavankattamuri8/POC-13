provider "aws" {
  region = "ap-south-1"
}

############################
# 1. EKS Cluster IAM Role
############################
resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role-poc"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

############################
# 2. EKS Cluster (Control Plane)
############################
resource "aws_eks_cluster" "poc" {
  name     = "poc-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn

  vpc_config {
    subnet_ids = [
      "subnet-090e9a807b975b807",
      "subnet-0c66dab8f1bfe1b3d",
      "subnet-0d1e4c8ddce1a11b9"
    ]
  }

  # ✅ 🔥 IMPORTANT FIX (ADD THIS)
  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

############################
# 3. IAM Role for Worker Nodes
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
# 4. Attach Policies to Node Role
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
# 5. Node Group (Worker Nodes)
############################
resource "aws_eks_node_group" "poc_nodes" {
  cluster_name    = aws_eks_cluster.poc.name
  node_group_name = "poc-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    "subnet-0f91618dbecad7449",
    "subnet-0b2c0c8a0af402202",
    "subnet-07c0ef75bcc4e0f9b"
  ]

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  instance_types = ["t3.micro"]

  depends_on = [
    aws_eks_cluster.poc,
    aws_iam_role_policy_attachment.eks_worker_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.ecr_readonly_policy
  ]
}
