# tgw-tester

Some examples of provisioning a Transit Gateway with Terraform and testing out connectivity across VPC's

## Examples

* `simple` - A simple example. TGW, VPC's, and instances in a single account.
* `separate_accounts` - A more difficult example. TGW and VPC's in one accounts. Subnets shared and instances in other accounts.
* `eks_subnet_sharing` - Fun with EKS. TGW and VPC's in one accounts. Subnets shared with an instance and EKS in other accounts.