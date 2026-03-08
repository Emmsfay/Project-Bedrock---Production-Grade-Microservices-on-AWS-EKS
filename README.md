# Project Bedrock — Production-Grade Microservices on AWS EKS

> **InnovateMart Inc.** | Cloud DevOps Capstone Project | Barakat Third Semester Exam

## Overview

Project Bedrock provisions a production-grade Kubernetes environment on AWS EKS for InnovateMart's microservices architecture. It includes full infrastructure-as-code, CI/CD automation, observability, secure developer access, and event-driven serverless components.

---

## Architecture

<img width="1536" height="1024" alt="ChatGPT Image Mar 8, 2026, 05_00_41 AM" src="https://github.com/user-attachments/assets/1655f226-e8ab-4fc4-a3a1-f96b26d58a68" />


### Components

| Component | Details |
|-----------|---------|
| **Cloud Provider** | AWS (us-east-1) |
| **IaC Tool** | Terraform (remote state on S3 + DynamoDB) |
| **VPC** | project-bedrock-vpc — 2 public + 2 private subnets across 2 AZs |
| **EKS Cluster** | project-bedrock-cluster — Kubernetes v1.33 |
| **Node Group** | 2x t3.medium (On-Demand) |
| **Application** | AWS Retail Store Sample App (retail-app namespace) |
| **Observability** | CloudWatch Container Insights + FluentBit |
| **Serverless** | S3 → Lambda event pipeline |
| **CI/CD** | GitHub Actions (plan on PR, apply on merge) |

---

## Prerequisites

- AWS CLI configured with admin credentials
- Terraform >= 1.6.0
- kubectl
- Helm (optional)
- Git

---

## Project Structure

```
project-bedrock/
├── .github/
│   └── workflows/
│       └── terraform.yml       # CI/CD pipeline
├── helm/
│   └── deploy-retail.sh        # Retail app deployment script
├── k8s/
│   └── namespace.yaml          # Kubernetes namespace
├── backend.tf                  # S3 + DynamoDB remote state
├── eks.tf                      # EKS cluster + node group + addons
├── iam.tf                      # IAM roles and policies
├── lambda.tf                   # S3 bucket + Lambda + trigger
├── lambda_function.py          # Lambda handler code
├── locals.tf                   # Local variables
├── namspace.tf                 # Kubernetes namespace resource
├── outputs.tf                  # Terraform outputs
├── provider.tf                 # AWS + Kubernetes providers
├── variables.tf                # Input variables
├── versions.tf                 # Provider version constraints
├── vpc.tf                      # VPC + subnets + NAT gateway
├── grading.json                # Terraform outputs for grading
└── README.md
```

---

## Infrastructure Setup

### 1. Clone the Repository

```bash
git clone https://github.com/Emmsfay/Project-Bedrock---Production-Grade-Microservices-on-AWS-EKS.git
cd Project-Bedrock---Production-Grade-Microservices-on-AWS-EKS
```

### 2. Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID, Secret, and region: us-east-1
```

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Deploy Infrastructure

```bash
terraform apply -var="student_id=<your-student-id>"
```

This provisions:
- VPC with public/private subnets
- EKS cluster and managed node group
- IAM roles and policies
- S3 bucket and Lambda function
- CloudWatch log groups

---

## Application Deployment

### Deploy the Retail Store App

```bash
bash helm/deploy-retail.sh
```

This script:
1. Updates your kubeconfig for the EKS cluster
2. Creates the `retail-app` namespace
3. Deploys the AWS Retail Store Sample App via Kubernetes manifests

### Verify Deployment

```bash
kubectl get pods -n retail-app
kubectl get svc -n retail-app
```

### Access the Application

```
http://a231b03ec853342cb92cad8e29c92a8d-764858626.us-east-1.elb.amazonaws.com
```

---

## CI/CD Pipeline

### How It Works

The GitHub Actions pipeline automates infrastructure changes:

| Trigger | Action |
|---------|--------|
| Pull Request to `main` | `terraform plan` |
| Merge/Push to `main` | `terraform apply -auto-approve` |

### Setup

1. Go to your GitHub repo → **Settings** → **Secrets and variables** → **Actions**
2. Add the following secrets:
   - `AWS_ACCESS_KEY_ID` — your AWS admin access key
   - `AWS_SECRET_ACCESS_KEY` — your AWS admin secret key

### Trigger a Plan (Pull Request)

```bash
git checkout -b feature/my-change
# make changes
git add .
git commit -m "My infrastructure change"
git push origin feature/my-change
# Open a Pull Request on GitHub → triggers terraform plan
```

### Trigger an Apply (Merge to Main)

```bash
# Merge the PR on GitHub → triggers terraform apply automatically
```

---

## Developer Access (bedrock-dev-view)

The `bedrock-dev-view` IAM user has two layers of access:

### AWS Console Access
- Attached policy: `ReadOnlyAccess` — can view all AWS resources but cannot modify them

### Kubernetes RBAC Access
- Mapped via EKS Access Entry to `AmazonEKSViewPolicy` scoped to the `retail-app` namespace
- Can run `kubectl get pods -n retail-app` ✅
- Cannot run `kubectl delete pod` ❌

### Configure Dev User Locally

```bash
aws configure --profile dev-user
# Enter bedrock-dev-view Access Key ID and Secret Key

aws eks update-kubeconfig \
  --name project-bedrock-cluster \
  --region us-east-1 \
  --profile dev-user

kubectl get pods -n retail-app       # Works ✅
kubectl delete pod <pod> -n retail-app  # Forbidden ❌
```

---

## Observability

### Control Plane Logs
EKS control plane logs are enabled for all log types and shipped to CloudWatch:
```
/aws/eks/project-bedrock-cluster/cluster
```
Log types: `api`, `audit`, `authenticator`, `controllerManager`, `scheduler`

### Container Logs
The Amazon CloudWatch Observability EKS Add-on runs FluentBit as a DaemonSet, shipping all container logs to:
```
/aws/containerinsights/project-bedrock-cluster/application
```

### View Logs

```bash
# Container logs
aws logs tail /aws/containerinsights/project-bedrock-cluster/application --follow

# Lambda logs
aws logs tail /aws/lambda/bedrock-asset-processor --follow
```

---

## Serverless Event Pipeline

### Flow
```
User uploads file → S3 (bedrock-assets-2354e) → Lambda trigger → bedrock-asset-processor → CloudWatch Logs
```

### Test It

```bash
echo "test" > test.jpg
aws s3 cp test.jpg s3://bedrock-assets-<your-student-id>/test.jpg
aws logs tail /aws/lambda/bedrock-asset-processor --follow
```

Expected log output:
```
Image received: test.jpg
```

### Lambda Code

```python
def lambda_handler(event, context):
    for record in event['Records']:
        key = record['s3']['object']['key']
        print(f"Image received: {key}")
    return {
        "statusCode": 200,
        "body": "Hello from Bedrock Lambda"
    }
```

---

## Remote State Management

Terraform state is stored remotely for team collaboration and CI/CD:

| Resource | Name |
|----------|------|
| S3 Bucket | `bedrock-tf-state-<student-id>` |
| DynamoDB Table | `bedrock-tf-locks` |
| State Key | `project-bedrock/terraform.tfstate` |

---

## Terraform Outputs

Run the following to generate the grading file:

```bash
terraform output -json > grading.json
```

| Output | Description |
|--------|-------------|
| `cluster_endpoint` | EKS API server endpoint |
| `cluster_name` | EKS cluster name |
| `region` | AWS region |
| `vpc_id` | VPC ID |
| `assets_bucket_name` | S3 assets bucket name |

---
## Image Result
<img width="1600" height="785" alt="Screenshot (199)" src="https://github.com/user-attachments/assets/9061e6a3-68e6-4dbc-b0ab-d93c673c3760" />

<img width="1861" height="953" alt="Screenshot (187)" src="https://github.com/user-attachments/assets/4cbe75c9-4e56-4691-88c6-08ecbaf67811" />

<img width="1920" height="980" alt="Screenshot (188)" src="https://github.com/user-attachments/assets/06dfae87-748f-4518-9783-7e69b2ea6081" />


<img width="1920" height="1080" alt="Screenshot (197)" src="https://github.com/user-attachments/assets/1b88e3bc-0e88-4873-8112-cdb80652088b" />


---

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy -var="id=<your-id>"
```

> ⚠️ This will delete all resources including the EKS cluster, VPC, S3 buckets, and Lambda function.

---

## Credentials

| Item | Value |
|------|-------|
| IAM User | `bedrock-dev-view` |
| Access Key ID | *(submitted separately)* |
| Secret Access Key | *(submitted separately)* |
| App URL | http://a231b03ec853342cb92cad8e29c92a8d-764858626.us-east-1.elb.amazonaws.com |

---

## Tags

`AWS` `EKS` `Kubernetes` `Terraform` `DevOps` `GitHub Actions` `CloudWatch` `Lambda` `S3` `InnovateMart`
