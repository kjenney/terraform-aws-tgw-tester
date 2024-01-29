locals {
  name   = "ex-tgw-${replace(basename(path.cwd), "_", "-")}"
  region = "us-east-1"
  cluster_name = "testertestypants"
  cluster_version = "1.29"

  tags = {
    TerraformManaged       = true
  }
}
