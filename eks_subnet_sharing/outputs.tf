output "vpc1_subnets" {
  value = module.vpc1.private_subnet_arns
}

output "vpc2_subnets" {
  value = module.vpc2.private_subnet_arns
}