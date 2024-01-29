## Test Instance on VPC2

module "ec2_vpc2" {
  source                    = "terraform-aws-modules/ec2-instance/aws"
  version                   = "~> 5.0"

  providers = {
    aws = aws.thirdaccount
  }

  name                      = "my-test-instance-vpc2"
  instance_type             = "t3.large"

  subnet_id                 = element(module.vpc2.private_subnets, 0)
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

  providers = {
    aws = aws.thirdaccount
  }

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

  depends_on = [aws_ram_resource_association.vpc2_subnets]
}
