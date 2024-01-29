# eks_subnet_sharing

* Provision a Transit Gatweay wth 2 VPC's. 
* The VPC's are provisioned in a single account.
* Provision an EC2 instance on one of the VPC's in a 2nd account.
* Provision an EKS cluster on the other VPC in a 3rd account.
* Connectivity is over the Transit Gateway

## Requirements

* 3 AWS accounts
* An IAM user in the 1st AWS account
* IAM roles in the other 2 accounts that can be assumed by the IAM user in the 1st AWS account
* AdministratorAccess policy attached to the IAM user and 2 IAM roles

## Setup

Replace `secondrole` and `thirdrole` with the ARN's of the IAM roles you created above.

```
MYIP=$(curl ifconfig.me)
terraform init
terraform plan \
    -var secondrole="REDACTED" \
    -var thirdrole="REDACTED" \
    -var eks_access_ip="$MYIP/32"
terraform apply \
    -var secondrole="REDACTED" \
    -var thirdrole="REDACTED" \
    -var eks_access_ip="$MYIP/32"
```

## Test

Login to the EKS cluster using `aws eks update-kubeconfig --name testertestypants`

Create service and Node Port:

```
kubectl apply -f nginx-deployment.yaml
kubectl create -f nodeport.yaml
```

Get NodePort to access the service: `kubectl get svc nginx-service-nodeport -oyaml | grep nodePort`

Get the IP addresses of the EKS nodes: `kubectl get node -oyaml | grep -B1 InternalIP`

Login to the EC2 instance in the 2nd account with Session Manager. 

`curl $IP $PORT` - where `IP` is an IP address from an EKS node and `PORT` is the Node Port.

## Cleanup

```
MYIP=$(curl ifconfig.me)
terraform destroy \
    -var secondrole="REDACTED" \
    -var thirdrole="REDACTED"
    -var eks_access_ip="$MYIP/32"
```