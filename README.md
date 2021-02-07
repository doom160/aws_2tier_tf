# goRedis_ECS_Example
## Architecture Diagram

![Architecture Diagram](screenshots/aws.jpg?raw=true "Architecture Diagram")

This is built in Golang. This application fetches data from Elasticache Redis and show visitor count.

## How to run this on your own?
1. Fork this repository
1. Add secret key AWS_ACCESS_KEY, AWS_SECRET_KEY
1. Update vars.tf for both AWS_ACCESS_KEY, AWS_SECRET_KEY
1. Run Terraform Script
`terraform apply`
1. Any feature branch PR triggers pipeline
`.github\workflows\go.yml`
1. Run following command to get your ALB DNS Name to visit your website
` aws elbv2 describe-load-balancers --output text --query "LoadBalancers[?LoadBalancerName =='go-redis'].DNSName"`
