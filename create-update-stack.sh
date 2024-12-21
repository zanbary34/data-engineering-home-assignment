#!/bin/bash
# shellcheck disable=SC2006

set -e

if [ -f .env ]; then
  source .env
fi

echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
echo "STACK_NAME: $STACK_NAME"
echo "AWS_REGION: $AWS_REGION"
echo "S3_BUCKET_NAME: $S3_BUCKET_NAME"

export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY

printf '\nUpdating stack...\n\n'

stack_yml="stack.yml"
stack=$STACK_NAME
region=$AWS_REGION
bucket_name=$S3_BUCKET_NAME

echo "Stack: $stack"
echo "Region: $region"
echo "S3 Bucket Name: $bucket_name"

stack_exists=`aws cloudformation describe-stacks --stack-name "$stack" --region "$region" || echo -1`

if test "$stack_exists" = "-1"
then
    echo "Creating a new stack: $stack in region $region"
    aws cloudformation create-stack --stack-name "$stack" \
        --region "$region" \
        --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --template-body file://"$stack_yml" \
        --parameters ParameterKey=S3BucketName,ParameterValue="$bucket_name"

    echo "Waiting for stack creation to complete: $stack in region $region"
    aws cloudformation wait stack-create-complete --stack-name "$stack" --region "$region"
    status=$?
else
    echo "Updating the stack: $stack in region $region"
    aws cloudformation update-stack --stack-name "$stack" \
        --region "$region" \
        --capabilities CAPABILITY_NAMED_IAM CAPABILITY_AUTO_EXPAND \
        --template-body file://"$stack_yml" \
        --parameters ParameterKey=S3BucketName,ParameterValue="$bucket_name"

    echo "Waiting for stack update to complete: $stack in region $region"
    aws cloudformation wait stack-update-complete --stack-name "$stack" --region "$region"
    status=$?
fi

if [[ $status -ne 0 ]]; then
    echo "$stack operation failed with AWS error code: $status."
    exit $status
else
    echo "$stack operation completed successfully in region $region."
fi

