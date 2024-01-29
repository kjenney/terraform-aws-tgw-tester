## Test EKS cluster and service on VPC2

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "19.21.0"

  providers = {
    aws = aws.thirdaccount
  }

  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  cluster_endpoint_public_access  = true
  cluster_endpoint_public_access_cidrs = [var.eks_access_ip]
  subnet_ids      = module.vpc2.private_subnets
  vpc_id          = module.vpc2.vpc_id
  tags            = local.tags
}

module "eks_managed_node_group" {
  source          = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"
  version         = "19.21.0"

  providers = {
    aws = aws.thirdaccount
  }

  name            = "separate-eks-mng"
  cluster_name    = local.cluster_name
  cluster_version = local.cluster_version
  subnet_ids      = module.vpc2.private_subnets
  cluster_primary_security_group_id = module.eks.cluster_primary_security_group_id
  vpc_security_group_ids            = [module.eks.node_security_group_id]

  min_size        = 1
  max_size        = 10
  desired_size    = 2

  instance_types  = ["t3.large"]
  capacity_type   = "SPOT"

  labels = {
    Environment   = "test"
    GithubRepo    = "terraform-aws-eks"
    GithubOrg     = "terraform-aws-modules"
  }

  tags            = local.tags
}

