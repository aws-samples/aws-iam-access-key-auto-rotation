data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

locals {
  aws_account_id = data.aws_caller_identity.current.account_id
  aws_partition  = data.aws_partition.current.partition
  aws_region = data.aws_region.current.name
}

##################################################################
# ASA IAM Role that will be assumed by the ASA IAM Key Rotation 
#  Function.
##################################################################

resource "aws_iam_role" "asa_iam_assumed_role" {
  name               = var.iam_role_name
  assume_role_policy = data.aws_iam_policy_document.asa_iam_assumed_role_trust_policy_document.json
}

data "aws_iam_policy_document" "asa_iam_assumed_role_trust_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [var.primary_account_id]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "asa_iam_assumed_role_policy" {
  role   = aws_iam_role.asa_iam_assumed_role.id
  name   = "AllowRotationFunctionPermissions"
  policy = data.aws_iam_policy_document.asa_iam_assumed_role_policy_document.json
}

data "aws_iam_policy_document" "asa_iam_assumed_role_policy_document" {
  statement {
    actions = [
      "iam:List*",
      "iam:CreatePolicy",
      "iam:CreateAccessKey",
      "iam:DeleteAccessKey",
      "iam:UpdateAccessKey",
      "iam:PutUserPolicy",
      "iam:GetUserPolicy",
      "iam:GetAccessKeyLastUsed",
      "iam:GetUser"
    ]
    resources = [
      "*"
    ]
  }
  statement {
    actions = [
      "iam:AttachUserPolicy"
    ]
    resources = [
      "arn:${local.aws_partition}:iam::${local.aws_account_id}:user/*"
    ]
  }
  statement {
    actions = [
      "iam:GetGroup"
    ]
    resources = [
      "arn:${local.aws_partition}:iam::${local.aws_account_id}:group/${var.iam_exemption_group}"
    ]
  }
  statement {
    actions = [
      "secretsmanager:PutResourcePolicy",
      "secretsmanager:PutSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:CreateSecret",
      "secretsmanager:GetResourcePolicy"
    ]
    resources = [
      "arn:${local.aws_partition}:secretsmanager:*:${local.aws_account_id}:secret:*"
    ]
  }
  statement {
    actions = [
      "sts:AssumeRole"
    ]
    resources = [
      "arn:${local.aws_partition}:iam::${var.primary_account_id}:role/${var.execution_role_name}"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"

      values = [var.aws_org_id]
    }
  }
}

##################################################################
# ASA IAM Group that will be used to manage account exemptions
##################################################################

resource "aws_iam_group" "asa_iam_exemptions_group" {
  name = var.iam_exemption_group
}
