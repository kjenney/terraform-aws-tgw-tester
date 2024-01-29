provider "aws" {
  region = local.region
}

locals {
  name   = "ex-tgw-${replace(basename(path.cwd), "_", "-")}"
  region = "us-east-1"

  tags = {
    TerraformManaged       = true
  }
}

################################################################################
# Transit Gateway Module
################################################################################

module "tgw" {
  source  = "terraform-aws-modules/transit-gateway/aws"
  version = "~> 2.0"

  name            = local.name
  description     = "My TGW"
  amazon_side_asn = 64532

  #transit_gateway_cidr_blocks = ["192.168.0.0/16","10.0.0.0/8"]
  transit_gateway_cidr_blocks = ["192.168.0.0/16"]

  enable_auto_accept_shared_attachments = true
  enable_default_route_table_propagation = true
  share_tgw = false

  # When "true", allows service discovery through IGMP
  enable_multicast_support = false

  vpc_attachments = {
    vpc1 = {
      vpc_id       = module.vpc1.vpc_id
      subnet_ids   = module.vpc1.private_subnets
      dns_support  = true
      ipv6_support = false

      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true

      tgw_routes = [
        {
          destination_cidr_block = module.vpc1.vpc_cidr_block
        }
      ]
    },
    vpc2 = {
      vpc_id     = module.vpc2.vpc_id
      subnet_ids = module.vpc2.private_subnets
      dns_support  = true
      ipv6_support = false

      transit_gateway_default_route_table_association = true
      transit_gateway_default_route_table_propagation = true

      tgw_routes = [
        {
          destination_cidr_block = module.vpc2.vpc_cidr_block
        }
      ]
      tags = {
        Name = "${local.name}-vpc2"
      }
    },
  }

  tags = local.tags
}

################################################################################
# Supporting resources
################################################################################

module "vpc1" {
  source                    = "terraform-aws-modules/vpc/aws"
  version                   = "~> 5.0"

  name                      = "${local.name}-vpc1"
  cidr                      = "10.10.0.0/16"

  enable_nat_gateway        = true
  single_nat_gateway        = true

  azs                       = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets           = ["10.10.1.0/24", "10.10.2.0/24", "10.10.3.0/24"]
  public_subnets            = ["10.10.4.0/24"]
  database_subnets          = ["10.10.5.0/24", "10.10.6.0/24", "10.10.7.0/24"]

  enable_ipv6               = false

  tags                      = local.tags
}

module "vpc2" {
  source                    = "terraform-aws-modules/vpc/aws"
  version                   = "~> 5.0"

  name                      = "${local.name}-vpc2"
  cidr                      = "192.168.0.0/20"

  enable_nat_gateway        = true
  single_nat_gateway        = true

  azs                       = ["${local.region}a", "${local.region}b", "${local.region}c"]
  private_subnets           = ["192.168.0.0/24", "192.168.1.0/24", "192.168.2.0/24"]
  public_subnets            = ["192.168.3.0/24"]
  database_subnets          = ["192.168.5.0/24", "192.168.6.0/24", "192.168.7.0/24"]

  enable_ipv6               = false

  tags                      = local.tags
}

# Routes to route over TGW between VPCs

resource "aws_route" "vpc1" {
  route_table_id            = module.vpc1.database_route_table_ids[0]
  destination_cidr_block    = module.vpc2.vpc_cidr_block
  transit_gateway_id        = module.tgw.ec2_transit_gateway_id
}

resource "aws_route" "vpc2" {
  route_table_id            = module.vpc2.database_route_table_ids[0]
  destination_cidr_block    = module.vpc1.vpc_cidr_block
  transit_gateway_id        = module.tgw.ec2_transit_gateway_id
}



## Test Instance on VPC1

module "ec2" {
  source                    = "terraform-aws-modules/ec2-instance/aws"
  version                   = "~> 5.0"

  name                      = "my-test-instance-vpc1"
  instance_type             = "t3.large"

  subnet_id                 = element(module.vpc1.database_subnets, 0)
  vpc_security_group_ids    = [module.security_group_instance.security_group_id]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

module "security_group_instance" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-ec2"
  description = "Security Group for EC2 Instance Egress"

  vpc_id = module.vpc1.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from VPC2"
      cidr_blocks = module.vpc2.vpc_cidr_block
    }
  ]

  egress_rules = ["all-all"]

  tags = local.tags
}

## Test Instance on VPC2

module "ec2_vpc2" {
  source                    = "terraform-aws-modules/ec2-instance/aws"
  version                   = "~> 5.0"

  name                      = "my-test-instance-vpc2"
  instance_type             = "t3.large"

  subnet_id                 = element(module.vpc2.database_subnets, 0)
  vpc_security_group_ids    = [module.security_group_instance_vpc2.security_group_id]

  create_iam_instance_profile = true
  iam_role_description        = "IAM role for EC2 instance"
  iam_role_policies = {
    AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  tags = local.tags
}

module "security_group_instance_vpc2" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${local.name}-ec2"
  description = "Security Group for EC2 Instance Egress"

  vpc_id = module.vpc2.vpc_id

  ingress_with_cidr_blocks = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      description = "SSH from VPC1"
      cidr_blocks = module.vpc1.vpc_cidr_block
    }
  ]
  egress_rules = ["all-all"]

  tags = local.tags
}