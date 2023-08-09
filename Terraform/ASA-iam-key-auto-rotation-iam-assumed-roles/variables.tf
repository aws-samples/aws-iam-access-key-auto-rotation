variable "aws_org_id" {
  description = "Enter your AWS Organization ID, this will be used to restricted execution permissions to only approved AWS Accounts within your AWS Organization."
}

variable "iam_exemption_group" {
  default     = "IAMKeyRotationExemptionGroup"
  description = "Manage IAM Key Rotation exemptions via an IAM Group. Enter the IAM Group name being used to facilitate IAM accounts excluded from auto-key rotation."
}

variable "iam_role_name" {
  default     = "asa-iam-key-rotation-lambda-assumed-role"
  description = "Enter the name of IAM Role that the main ASA-iam-key-auto-rotation-and-notifier-solution will assume."
}

variable "execution_role_name" {
  default     = "asa-iam-key-rotation-lambda-execution-role"
  description = "Enter the name of IAM Execution Role that will assume the sub-account role for Lambda Execution."
}

variable "primary_account_id" {
  description = "Enter the primary AWS Account ID that will you will be deploying the ASA-iam-key-auto-rotation-and-notifier-solution to."
}
