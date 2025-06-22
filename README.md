
# Self-Healing EC2 Auto-Remediation System

This project implements a self-healing infrastructure for Amazon EC2 using Terraform, AWS Lambda, CloudWatch, and SNS. It monitors EC2 instance health and automatically replaces unhealthy instances with minimal downtime using an Auto Scaling Group (ASG). The goal is to enhance availability and reduce the need for manual intervention.

## Features

- Monitors EC2 instance health with CloudWatch alarms
- Sends automated alerts through AWS SNS
- Triggers an AWS Lambda function to terminate unhealthy EC2 instances
- Automatically provisions replacement instances via an Auto Scaling Group
- Infrastructure is fully defined and managed using Terraform

## Architecture Overview

```
CloudWatch Alarm (Unhealthy EC2)
        |
        v
    SNS Topic --> Email or Webhook Alert
        |
        v
  Lambda Function (Terminate EC2 Instance)
        |
        v
Auto Scaling Group (Launch Replacement Instance)
```

## Project Structure

```
Self-Healing-EC2-Auto-Remediation-System/
├── aws_provider/
│   ├── main.tf           # Defines ASG, EC2, CloudWatch, SNS
│   ├── provider.tf       # AWS provider configuration
│   └── variables.tf      # Input variables for customization
├── lambda/
│   ├── lambda.py         # Lambda function to terminate EC2 instances
│   └── lambda.zip        # Zipped function ready for deployment
└── README.md             # Project documentation
```

## Prerequisites

- Terraform installed and configured
- AWS CLI configured with appropriate credentials
- IAM permissions to manage EC2, Auto Scaling, Lambda, CloudWatch, and SNS

## Deployment Instructions

1. Clone the repository:
   ```bash
   git clone https://github.com/FrancescoCheema/Self-Healing-EC2-Auto-Remediation-System.git
   cd Self-Healing-EC2-Auto-Remediation-System/aws_provider
   ```

2. Initialize and apply Terraform:
   ```bash
   terraform init
   terraform apply
   ```

3. Deploy the Lambda function:
   - Option A: Upload `lambda.zip` manually through the AWS Console
   - Option B: Use AWS CLI to update the function code

## Configuration Notes

- The SNS topic is defined in `main.tf`. Update the subscription with your preferred email or webhook.
- Make sure your Lambda execution role has permission to terminate EC2 instances.
- Ensure the launch template and ASG are configured to maintain desired capacity.
