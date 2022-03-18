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

variable "s3_bucket_name" {
  description = "S3 Bucket Name where code is located."
}

variable "s3_bucket_prefix" {
  default     = "asa/asa-iam-rotation"
  description = "The prefix or directory where resources will be stored."
}

variable "admin_email_address" {
  description = "Email address that will be used in the 'sent from' section of the email."
}

variable "email_template_enforce" {
  default     = "iam-auto-key-rotation-enforcement.html"
  description = "Enter the file name of the email html template to be sent out by the Notifier Module for Enforce Mode. Note: Must be located in the 'S3 Bucket Prefix/Template/template_name.html' folder"
}

variable "email_template_audit" {
  default     = "iam-auto-key-rotation-enforcement.html"
  description = "Enter the file name of the email html template to be sent out by the Notifier Module for Audit Mode. Note: Must be located in the 'S3 Bucket Prefix/Template/template_name.html' folder"
}

variable "rotation_period" {
  type        = number
  description = "The number of days after which a key should be rotated (rotating from active to inactive)."
  default     = 90
}

variable "inactive_period" {
  type        = number
  description = "The number of days after which to inactivate keys that had been rotated (Note: This must be greater than RotationPeriod)."
  default     = 90
}
variable "inactive_buffer" {
  type        = number
  description = "The grace period between rotation and deactivation of a key."
  default     = 10
}

variable "recovery_grace_period" {
  type        = number
  description = "Recovery grace period between deactivation and deletion."
  default     = 10
}

variable "dry_run_flag" {
  description = "Enables/Disables key rotation functionality. 'True' only sends notifications to end users (Audit Mode). 'False' preforms key rotation and sends notifications to end users (Remediation Mode)."
  default     = "True"
}
