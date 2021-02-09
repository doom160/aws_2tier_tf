#! /bin/sh

WORKSPACE=`pwd`

# Package Artifact
#rm -f src/generate_rds_schema/generate_rds_schema.zip
#cd src/generate_rds_schema && pip install --target packages pymysql && zip generate_rds_schema.zip *

# Create Role
cd $WORKSPACE
aws iam create-role --role-name lambda-ex --assume-role-policy-document '{"Version": "2012-10-17","Statement": [{ "Effect": "Allow", "Principal": {"Service": "lambda.amazonaws.com"}, "Action": "sts:AssumeRole"}]}'
aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole
aws iam attach-role-policy --role-name lambda-ex --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole

# Get Role ARN
ROLE_ARN=`aws iam list-roles --output text --query "Roles[?RoleName == 'lambda-ex' ].Arn"`
VPC_ID=`aws ec2 describe-vpcs --filters Name=tag:env,Values=dev --output text --query "Vpcs[*].VpcId"`
SUBNET_ID=`aws ec2 describe-subnets --filter Name=vpc-id,Values=$VPC_ID --filter "Name=cidr-block,Values=10.0.4.0/24" --output text --query "Subnets[*].SubnetId"`
SECURITY_GROUP_ID=`aws ec2 describe-security-groups --query "SecurityGroups[?GroupName == 'private_rule'].GroupId" --output text`
aws lambda create-function --function-name generate_rds_schema --zip-file fileb://src/generate_rds_schema/generate_rds_schema.zip --handler app.lambda_handler --runtime python3.8 --role $ROLE_ARN --vpc-config SubnetIds=$SUBNET_ID,SecurityGroupIds=$SECURITY_GROUP_ID

echo Sleep 3min to wait for Lambda function to be ready
sleep 180

# Get DB Endpoint
DB_HOST=`aws rds describe-db-instances --query "DBInstances[?DBInstanceIdentifier == 'dev-node-app-rds'].Endpoint.Address" --output text`

# Invoke Lambda function
aws lambda invoke --function-name generate_rds_schema --payload '{"DB_HOST": "'$DB_HOST'"}' output.txt

