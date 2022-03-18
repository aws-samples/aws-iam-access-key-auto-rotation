data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  aws_region = data.aws_region.current.name
}

##################################################################
# [ASA Notifier Module] Lambda Role & Function
##################################################################

# role
resource "aws_iam_role" "notifier_function_execution_role" {
  name                = "asa-notifier-lambda-execution-role"
  assume_role_policy  = data.aws_iam_policy_document.notifier_function_execution_role_trust_policy_document.json
  managed_policy_arns = ["arn:${local.aws_partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]
}

# trust policy
data "aws_iam_policy_document" "notifier_function_execution_role_trust_policy_document" {
  statement {
    sid    = "AllowExecutionPermissionsOnFunction"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# inline role policy
resource "aws_iam_role_policy" "notifier_function_execution_role_policy" {
  role   = aws_iam_role.notifier_function_execution_role.id
  name   = "AllowNotiferToGetEmailTemplate"
  policy = data.aws_iam_policy_document.notifier_function_execution_role_policy_document.json
}

# inline role policy document
data "aws_iam_policy_document" "notifier_function_execution_role_policy_document" {
  statement {
    actions = [
      "s3:GetObject"
    ]
    resources = [
      "arn:${local.aws_partition}:s3:::${var.s3_bucket_name}/${var.s3_bucket_prefix}/Template/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"

      values = [var.aws_org_id]
    }
  }
  statement {
    actions = [
      "ses:SendEmail"
    ]
    resources = [
      "arn:${local.aws_partition}:ses:${local.aws_region}:${local.aws_account_id}:identity/*"
    ]
  }
}

# lambda function
resource "aws_lambda_function" "notifier_lambda_function" {
  s3_bucket = var.s3_bucket_name
  s3_key = "${var.s3_bucket_prefix}/Lambda/notifier.zip"
  function_name = "ASA-Notifier"
  role          = aws_iam_role.notifier_function_execution_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  timeout       = "300"
  description   = "Function that received SNS events from config rules and emails end users who own the account id of the resource violation."
  environment {
    variables = {
      ADMIN_EMAIL      = "${var.admin_email_address}"
      S3_BUCKET_NAME   = "${var.s3_bucket_name}"
      S3_BUCKET_PREFIX = "${var.s3_bucket_prefix}"
    }
  }
}

##################################################################
# [AWS IAM Access Keys Rotation Module] Lambda Role & Function
##################################################################

# role
resource "aws_iam_role" "rotation_lambda_function_execution_role" {
  name                = var.execution_role_name
  assume_role_policy  = data.aws_iam_policy_document.rotation_lambda_function_execution_role_trust_policy_document.json
  managed_policy_arns = ["arn:${local.aws_partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  depends_on = [aws_lambda_function.notifier_lambda_function]
}

# trust policy
data "aws_iam_policy_document" "rotation_lambda_function_execution_role_trust_policy_document" {
  statement {
    sid    = "AllowExecutionPermissionsOnFunction"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# inline role policy
resource "aws_iam_role_policy" "rotation_lambda_function_execution_role_policy" {
  role   = aws_iam_role.rotation_lambda_function_execution_role.id
  name   = "AllowRotationFunctionPermissions"
  policy = data.aws_iam_policy_document.rotation_lambda_function_execution_role_policy_document.json
}

# inline role policy document
data "aws_iam_policy_document" "rotation_lambda_function_execution_role_policy_document" {
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:${local.aws_partition}:iam::*:role/${var.iam_role_name}"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"

      values = [var.aws_org_id]
    }
  }
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.notifier_lambda_function.arn
    ]
  }
}

# lambda function
resource "aws_lambda_function" "access_key_rotate_lambda_function" {
  s3_bucket = var.s3_bucket_name
  s3_key = "${var.s3_bucket_prefix}/Lambda/access_key_auto_rotation.zip"
  function_name = "ASA-IAM-Access-Key-Rotation-Function"
  role          = aws_iam_role.rotation_lambda_function_execution_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.8"
  timeout       = "400"
  description   = "ASA Function to rotate IAM Access Keys on specified schedule"
  environment {
    variables = {
      DryRunFlag           = "${var.dry_run_flag}"
      RotationPeriod       = "${var.rotation_period}"
      InactivePeriod       = "${var.inactive_period}"
      InactiveBuffer       = "${var.inactive_buffer}"
      RecoveryGracePeriod  = "${var.recovery_grace_period}"
      IAMExemptionGroup    = "${var.iam_exemption_group}"
      IAMAssumedRoleName   = "${var.iam_role_name}"
      RoleSessionName      = "ASA-IAM-Access-Key-Rotation-Function"
      Partition            = "${local.aws_partition}"
      NotifierArn          = aws_lambda_function.notifier_lambda_function.arn
      EmailTemplateEnforce = var.email_template_enforce
      EmailTemplateAudit   = var.email_template_audit
    }
  }
}

##################################################################
# [AWS Account & Email Inventory Module] Lambda Role & Function
##################################################################

# role
resource "aws_iam_role" "account_inventory_function_execution_role" {
  name                = "asa-account-inventory-lambda-execution-role"
  assume_role_policy  = data.aws_iam_policy_document.account_inventory_function_execution_role_trust_policy_document.json
  managed_policy_arns = ["arn:${local.aws_partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"]

  depends_on = [aws_lambda_function.notifier_lambda_function]
}

# trust policy
data "aws_iam_policy_document" "account_inventory_function_execution_role_trust_policy_document" {
  statement {
    sid    = "AllowExecutionPermissionsOnFunction"
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# inline role policy
resource "aws_iam_role_policy" "account_inventory_function_execution_role_policy" {
  role   = aws_iam_role.account_inventory_function_execution_role.id
  name   = "AllowAWSOrgAccess"
  policy = data.aws_iam_policy_document.account_inventory_function_execution_role_policy_document.json
}

# inline role policy document
data "aws_iam_policy_document" "account_inventory_function_execution_role_policy_document" {
  statement {
    actions = [
      "organizations:ListAccounts"
    ]
    resources = [
      "*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"

      values = [var.aws_org_id]
    }
  }
  statement {
    actions = [
      "lambda:InvokeFunction"
    ]
    resources = [
      aws_lambda_function.access_key_rotate_lambda_function.arn
    ]
  }
}

# lambda function
resource "aws_lambda_function" "account_inventory_lambda_function" {
  s3_bucket = var.s3_bucket_name
  s3_key = "${var.s3_bucket_prefix}/Lambda/account_inventory.zip"
  function_name = "ASA-Account-Inventory"
  role          = aws_iam_role.account_inventory_function_execution_role.arn
  handler       = "account_inventory.lambda_handler"
  runtime       = "python3.8"
  timeout       = "300"
  description   = "Function that calls the DescribeAccount & ListAccounts on AWS Organizations to collect all AWS Account IDs and corresponding Emails."
  environment {
    variables = {
      LambdaRotationFunction = aws_lambda_function.access_key_rotate_lambda_function.function_name
    }
  }
}

##################################################################
# Permissions to allow AccountInventoryLambdaFunction to Invoke
#    Notifier Lambda Function 
##################################################################

resource "aws_lambda_permission" "rotation_access_key_rotate_lambda_invoke_lambda_permissions" {
  function_name = aws_lambda_function.notifier_lambda_function.function_name
  action        = "lambda:InvokeFunction"
  principal     = local.aws_account_id
  source_arn    = "arn:${local.aws_partition}:sts::${local.aws_account_id}:assumed-role/${var.execution_role_name}/${aws_lambda_function.account_inventory_lambda_function.function_name}"
}

##################################################################
# Permissions to allow AccountInventoryLambdaFunction to Invoke
#     Key Rotate Lambda Function 
##################################################################

resource "aws_lambda_permission" "account_inventory_trigger_lambda_permissions" {
  function_name = aws_lambda_function.access_key_rotate_lambda_function.function_name
  action        = "lambda:InvokeFunction"
  principal     = local.aws_account_id
  source_arn    = "arn:${local.aws_partition}:sts::${local.aws_account_id}:assumed-role/${var.execution_role_name}/${aws_lambda_function.account_inventory_lambda_function.function_name}"
}

##################################################################
# CloudWatch event trigger to run AccountInventoryFunction 
#   Function on a schedule. rate(24 hours) = Once a Day
##################################################################

# cloudwatch event
resource "aws_cloudwatch_event_rule" "rotation_cloudwatch_event_lambda_trigger" {
  description         = "CloudWatch Event to trigger Access Key auto-rotation Lambda Function daily"
  schedule_expression = "rate(24 hours)"
  is_enabled          = true
}

# cloudwatch event target
resource "aws_cloudwatch_event_target" "rotation_cloudwatch_event_target" {
  rule      = aws_cloudwatch_event_rule.rotation_cloudwatch_event_lambda_trigger.name
  target_id = "AccountInventoryLambdaFunction"
  arn       = aws_lambda_function.account_inventory_lambda_function.arn
}

# lambda permission
resource "aws_lambda_permission" "rotation_cloudwatch_event_lambda_trigger_lambda_permissions" {
  function_name = aws_lambda_function.access_key_rotate_lambda_function.function_name
  action        = "lambda:InvokeFunction"
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.rotation_cloudwatch_event_lambda_trigger.arn

  depends_on = [aws_cloudwatch_event_rule.rotation_cloudwatch_event_lambda_trigger]
}
