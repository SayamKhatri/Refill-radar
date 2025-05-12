# Refill-radar
Refill-Radar is a real-time alerting platform that monitors inventory levels and instantly notifies relevant team when any product stock drops below a predefined threshold.It is built entirely on AWS services with CI/CD pipelines, the project is designed to showcase a robust Change Data Capture (CDC) pipeline powered by AWS RDS, AWS DMS, Kinesis, Lambda, and DynamoDB, with a Streamlit dashboard for real-time monitoring.

## Architecture Overview

1. **Source Database**: MySQL hosted on Amazon RDS, containing inventory data.
2. **AWS DMS**: Configured in CDC mode to capture changes to the `inventory` table that is in our RDS instance. 
3. **Kinesis Data Stream**: Receives real-time change events from DMS.
4. **Lambda Function**: Triggered by Kinesis. It reads each event, fetches threshold values from S3, and compares them against current inventory levels.
5. **DynamoDB**: Stores alerts with a TTL set for automatic cleanup.
6. **SNS**: Sends email notifications for stockouts.
7. **Streamlit Dashboard**: Reads from DynamoDB and displays alerts live.



## Folder Structure

```
Refill-radar/
├── .github/
│   └── workflows/
│       └── deploy.yml
├── aws-backend/
│   ├── backend.tf
│   ├── dms-task-settings.json
│   ├── dms.tf
│   ├── dynamodb.tf
│   ├── iam-wait.tf
│   ├── iam.tf
│   ├── kinesis.tf
│   ├── lambda.tf
│   ├── main.tf
│   ├── outputs.tf
│   ├── sns.tf
│   └── variables.tf
├── backend-bootstrap-aws/
│   ├── .terraform.lock.hcl
│   └── main.tf
├── Dashboard/
│   └── app.py
├── lambda/
│   ├── inventory_alert_handler.zip
│   └── lambda_function.py
├── .gitignore
├── LICENSE
└── README.md


```


## Technologies Used

* **AWS RDS** (Our OLTP database)
* **AWS DMS** (Change Data Capture from RDS to Kinesis)
* **AWS Kinesis** (streaming changes)
* **AWS Lambda** (business logic + alerting)
* **Amazon S3** (stores product threshold CSV)
* **Amazon SNS** (email notifications)
* **Amazon DynamoDB** (stores alerts with TTL)
* **Streamlit** (dashboard frontend)
* **Terraform** (infrastructure as code)
* **GitHub Actions** (CI/CD pipeline)


## Getting Started

### 1. Setup Terraform Backend (One-Time)

```
cd terraform/backend
terraform init
terraform apply -auto-approve
```

### 2. Deploy Infra via CI/CD

Push changes to `main` branch. GitHub Actions will handle:

* Terraform init
* Terraform plan
* Terraform apply

Secrets (like `rds_username`, `rds_password`, etc.) are securely stored as GitHub secrets.

### 3. Run Dashboard

```
cd dashboard
streamlit run app.py
```
