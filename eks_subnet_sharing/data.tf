data "aws_caller_identity" "secondaccount" {
  provider  = aws.secondaccount
}

data "aws_caller_identity" "thirdaccount" {
  provider  = aws.thirdaccount
}

data "aws_eks_cluster_auth" "main" {
  name = local.cluster_name
}