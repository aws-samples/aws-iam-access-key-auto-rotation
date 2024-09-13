terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}
data "aws_caller_identity" "current" {}
resource "aws_iam_role" "test_role" {
  name = "asa-iam-key-rotation-lambda-assumed-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          AWS = "arn:aws:iam::(account_infra):role/asa-iam-key-rotation-lambda-execution-role"  # Informar account id do ambiente desejado
        }
      },
    ]
  })

  tags = {
    environment = "dev"
  }
}
resource "aws_iam_role_policy" "test_policy" {
  name = "AllowRotationFunctionPermissions"
  role = aws_iam_role.test_role.id

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "iam:List*",
                "iam:CreatePolicy",
                "iam:CreateAccessKey",
                "iam:DeleteAccessKey",
                "iam:UpdateAccessKey",
                "iam:PutUserPolicy",
                "iam:GetUserPolicy",
                "iam:GetAccessKeyLastUsed",
                "iam:GetUser"
            ],
            "Resource": "*",
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:AttachUserPolicy"
            ],
            "Resource": [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "secretsmanager:PutResourcePolicy",
                "secretsmanager:PutSecretValue",
                "secretsmanager:DescribeSecret",
                "secretsmanager:CreateSecret",
                "secretsmanager:GetResourcePolicy",
                "secretsmanager:ReplicateSecretToRegions"
            ],
            "Resource": [
                "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:*"
            ],
            "Effect": "Allow"
        },
        {
            "Action": [
                "iam:GetGroup"
            ],
            "Resource": [
                "arn:aws:iam::${data.aws_caller_identity.current.account_id}:group/IAMKeyRotationExemptionGroup"
            ],
            "Effect": "Allow"
        }
    ]
  })
}
resource "aws_iam_group" "developers" {
  name = "IAMKeyRotationExemptionGroup"
}