## Test Instance on VPC1

module "ec2" {
  source                    = "terraform-aws-modules/ec2-instance/aws"
  version                   = "~> 5.0"

  providers = {
    aws = aws.secondaccount
  }

  name                      = "my-test-instance-vpc1"
  instance_type             = "t3.large"

  subnet_id                 = element(module.vpc1.private_subnets, 0)
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

  providers = {
    aws = aws.secondaccount
  }

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