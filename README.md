# NodeJs
## Architecture Diagram

![Architecture Diagram](screenshots/aws.jpg?raw=true "Architecture Diagram")

## Terraform script for 2 Tier Architecture
These scripts create:
* Standard Public and Private Subnets across 3 Azs for maximum high availability
* Public Subnet as standard is routed to internet gateway and attached to a NAT Gateway
* Application are built as Docker image and pushed to ECR
* Application runs on ECS Fargate to reduce the effort to run underlying infrastructure
* Application are configured with autoscaling policy based on CPU and Memory
* Application is Load Balanced with an ALB and perform Layer 7 Http Check. On the ECS task definition, it can define Layer 4 TCP Check.
* Database runs on RDS MySQL multi-AZ setup for high availability. Running on RDS reduce the effort to run the underlying infrastructure. Its running in the private subnet to block internet traffic
* Separate Lambda function to create the default schema for the database as database is accessible in the private subnet


## Disclaimer
This setup is not fully readily PROD setup due to following points
* Security Groups are open to the whole vpc, which ideally should be open to ports that required. It was done intentionally for simplicity of development and testing
* DB in this setup is running t2.small which is not production grade
* DB can be further enhanced to use read replicas
* ECR can be replaced with EKS. ECS was chosen as it was taken from TF template developed earlier by me for simplicity of development

## How to run this on your own?
1. Initialize and Create multiple workspace
```
terraform init 
terraform workspace new dev
terraform workspace new uat
terraform workspace new prod
terraform workspace select dev
```
2. Create variable terraform file `terraform.tfvars`
```
AWS_REGION="ap-southeast-1"
AWS_SECRET_KEY="SECRET_KEY"
AWS_ACCESS_KEY="ACCESS_KEY"
```
3. Apply terraform script
```
terraform plan
terraform apply
```
4. Create DB Schema via Lambda function

```
chmod +x deploy_lambda.sh
./deploy_lambda.sh
```

