locals {
  name   = "ex-tgw-${replace(basename(path.cwd), "_", "-")}"
  region = "us-east-1"

  tags = {
    TerraformManaged       = true
  }
}
