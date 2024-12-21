#!/bin/bash

set -e

if [ -f .env ]; then
  source .env
else
  echo "Error: .env file not found. Please create a .env file with the required variables."
  exit 1
fi

if [ -z "$AWS_REGION" ] || [ -z "$S3_BUCKET_NAME" ] || [ -z "$GLUE_JOB_NAME" ] || [ -z "$GLUE_CRAWLER_NAME" ]; then
  echo "Error: Missing one or more required environment variables: AWS_REGION, S3_BUCKET_NAME, GLUE_JOB_NAME, GLUE_CRAWLER_NAME."
  exit 1
fi

bucket_name="$S3_BUCKET_NAME"
script_path="script/assignment.py"
dataset_path="input/stocks_data.csv"

echo "Uploading PySpark script to S3 bucket: $bucket_name/scripts/"
aws s3 cp $script_path s3://$bucket_name/scripts/

if [ $? -eq 0 ]; then
  echo "Script uploaded successfully to S3 bucket: $bucket_name/scripts/"
else
  echo "Failed to upload script to S3 bucket: $bucket_name/scripts/"
  exit 1
fi

echo "Uploading dataset to S3 bucket: $bucket_name/input/"
aws s3 cp $dataset_path s3://$bucket_name/input/

if [ $? -eq 0 ]; then
  echo "Dataset uploaded successfully to S3 bucket: $bucket_name/input/"
else
  echo "Failed to upload dataset to S3 bucket: $bucket_name/input/"
  exit 1
fi

echo "Starting Glue job: $GLUE_JOB_NAME"
job_run_id=$(aws glue start-job-run --job-name $GLUE_JOB_NAME --region $AWS_REGION --query 'JobRunId' --output text)

if [ $? -eq 0 ]; then
  echo "Glue job started successfully: $GLUE_JOB_NAME, JobRunId: $job_run_id"
else
  echo "Failed to start Glue job: $GLUE_JOB_NAME"
  exit 1
fi

echo "Waiting for Glue job to complete..."
job_status="STARTING"
while [[ "$job_status" != "SUCCEEDED" && "$job_status" != "FAILED" && "$job_status" != "STOPPED" ]]; do
  sleep 10
  job_status=$(aws glue get-job-run --job-name $GLUE_JOB_NAME --run-id $job_run_id --region $AWS_REGION --query 'JobRun.JobRunState' --output text)
  echo "Current Glue job status: $job_status"
done

if [ "$job_status" == "SUCCEEDED" ]; then
  echo "Glue job completed successfully."\else
  echo "Glue job failed or was stopped. Status: $job_status"
fi

echo "Starting Glue crawler: $GLUE_CRAWLER_NAME"
aws glue start-crawler --name $GLUE_CRAWLER_NAME --region $AWS_REGION

if [ $? -eq 0 ]; then
  echo "Glue crawler started successfully: $GLUE_CRAWLER_NAME"
else
  echo "Failed to start Glue crawler: $GLUE_CRAWLER_NAME"
  exit 1
fi

echo "Waiting for Glue crawler to complete..."
crawler_status="RUNNING"
while [[ "$crawler_status" != "SUCCEEDED" && "$crawler_status" != "FAILED" ]]; do
  sleep 10
  crawler_status=$(aws glue get-crawler --name $GLUE_CRAWLER_NAME --region $AWS_REGION --query 'Crawler.State' --output text)
  echo "Current Glue crawler status: $crawler_status"
done

if [ "$crawler_status" == "READY" ]; then
  echo "Glue crawler completed successfully."\else
  echo "Glue crawler failed. Status: $crawler_status"
fi

echo "All tasks completed successfully!"
exit 1