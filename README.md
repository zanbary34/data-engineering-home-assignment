# How to Run the Data Engineering Solution


## **Step 1: Clone the Repository**

crate the .env file exists in the root directory. This file should contain the following configurations:

AWS_ACCESS_KEY_ID=**secret**
AWS_SECRET_ACCESS_KEY=**secret**
STACK_NAME=zanbary
AWS_REGION=eu-central-1
S3_BUCKET_NAME=sefi-data-engineer-assignment
GLUE_JOB_NAME=sefi-data-engineer-assignment-job
GLUE_CRAWLER_NAME=sefi-assignment-crawler

Note: Replace AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY with the credentials you received via email.
## **Step 2: Create or Update Infrastructure**
 Run the `create-update-stack.sh` script to provision the necessary AWS resources:
   ```bash
   bash create-update-stack.sh
   ```
   **What This Does:**
   - Creates or updates an S3 bucket for storing input and output files.
   - Configures the AWS Glue job to process the stock data.
   - Create Data table catalog
   - Sets up the Glue crawler to update the Glue Data Catalog.



## **Step 3: Upload Files and Run the Glue Job**
 Execute the `upload-and-run.sh` script to upload the files and start the Glue job:
   ```bash
   bash upload-and-run.sh
   ```
   **What This Does:**
   - Uploads the `assignment.py` script and `stocks_data.csv` dataset to the S3 bucket.
   - Starts the Glue job, which:
     - Processes the data and calculates the required metrics.
     - Saves the output to the S3 bucket in the following directories:
       - `output/average_daily_return/`
       - `output/highest_worth/`
       - `output/most_volatile/`
       - `output/top_30_day_returns/`
   - Triggers the Glue crawler to update the Data Catalog with the processed results.

---

## **Step 4: Query Results**
1. Use AWS Glue Data Catalog and Athena to query the processed data.

2. Example queries:
   - **Check average daily return for a specific date:**
     ```sql
     SELECT * FROM "sefi-data_engineer_assignment_db"."processed_average_daily_return" WHERE date = '2022-06-17';
     ```
   - **Find the most volatile stock:**
     ```sql
     SELECT * FROM "sefi-data_engineer_assignment_db"."processed_most_volatile_stock";
     ```

3. Results are queryable directly in Athena or any other tool integrated with the Glue Data Catalog.

---

## **Outcome**
- The solution processes stock data to calculate:
  - Average daily returns.
  - Highest worth stock.
  - Most volatile stock.
  - Top 30-day return dates.
- Results are stored in S3 and are queryable via Athena.

This setup ensures scalability, automation, and ease of use in a cloud environment.

