provider "aws" {
  region = local.region
}

provider "aws" {
  region = local.region
  alias  = "secondaccount"

  assume_role {
    role_arn    = var.secondrole
  }
}

provider "aws" {
  region = local.region
  alias  = "thirdaccount"

  assume_role {
    role_arn    = var.thirdrole
  }
}

provider "kubernetes" {
  host                    = module.eks.cluster_endpoint

  token                   = data.aws_eks_cluster_auth.main.token
  cluster_ca_certificate  = base64decode(module.eks.cluster_certificate_authority_data)
}
