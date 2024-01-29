# simple

Provision a Transit Gatweay wth 2 VPC's, each with an EC2 instance to test connectivity.

## Setup

```
terraform init
terraform plan
terraform apply
```

## Test

Login to one of the instances with Session Manager. Take note of the other instances IP address. 

Run `ssh $OTHERIP` - where OTHERIP is the IP address of the other instance.


## Cleanup

`terraform destroy`
