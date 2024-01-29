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

# Share subnets

resource "aws_ram_resource_share" "secondaccount" {
  name                        = "sharewithsecondaccount"
}

resource "aws_ram_resource_share" "thirdaccount" {
  name                        = "sharewiththirdaccount"
}

resource "aws_ram_principal_association" "secondaccount" {
  principal          = data.aws_caller_identity.secondaccount.account_id
  resource_share_arn = aws_ram_resource_share.secondaccount.arn
}

resource "aws_ram_principal_association" "thirdaccount" {
  principal          = data.aws_caller_identity.thirdaccount.account_id
  resource_share_arn = aws_ram_resource_share.thirdaccount.arn
}

resource "aws_ram_resource_association" "vpc1_subnets" {
  count               = length(module.vpc1.private_subnet_arns)
  resource_arn        = module.vpc1.private_subnet_arns[count.index]
  resource_share_arn  = aws_ram_resource_share.secondaccount.arn
}

resource "aws_ram_resource_association" "vpc2_subnets" {
  count               = length(module.vpc2.private_subnet_arns)
  resource_arn        = module.vpc2.private_subnet_arns[count.index]
  resource_share_arn  = aws_ram_resource_share.thirdaccount.arn
}