output "vpc1_subnets" {
  value = module.vpc1.private_subnet_arns
}

output "vpc2_subnets" {
  value = module.vpc2.private_subnet_arns
}

#output "eks_service_address" {
#  value = module.eks_service.private_address
#}