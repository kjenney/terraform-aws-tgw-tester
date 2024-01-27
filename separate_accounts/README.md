# tgw-tester

Provision a Transit Gatweay wth 2 VPC's, each with an EC2 instance to test connectivity. The VPC's are provisioned in a single account but shared to 2 separate accounts. The EC2 instances are in the separate accounts, but connectivity is still over the Transit Gateway.

## Requirements

* 3 AWS accounts
* An IAM user in the first AWS account
* IAM roles in the other 2 accounts that can be assumed by the IAM user in the first AWS account
* AdministratorAccess policy attached to the IAM user and 2 IAM roles

Ensure that you have 3 AWS accounts.

## Setup

Replace `secondrole` and `thirdrole` with the ARN's of the IAM roles you created above.

```
terraform init
terraform plan \
    -var secondrole="REDACTED" \
    -var thirdrole="REDACTED"
terraform apply \
    -var secondrole="REDACTED" \
    -var thirdrole="REDACTED"
```

## Test

Note the Terraform output from above - specifically `vp2_intance_ip`.

Login to the instance in the second account with Session Manager. 

Run `ssh $vp2_intance_ip` - where `vp2_intance_ip` is the value of the Terraform output from above.

## Cleanup

```
terraform destroy \
    -var secondrole="REDACTED" \
    -var thirdrole="REDACTED"
```