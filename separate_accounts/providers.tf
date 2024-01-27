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

