data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = ["*${terraform.workspace}*"]
  }
}

data "aws_subnets" "public" {
  count = terraform.workspace == "dev" ? 0 : 1

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "sn-${terraform.workspace}-dm*-ext-us-east-*"
  }
}

data "aws_subnets" "webapp" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "sn-${terraform.workspace}-webapp-us-east-*"
  }
}

data "aws_subnets" "database" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "sn-${terraform.workspace}-db-us-east-*"
  }
}

data "aws_acm_certificate" "amazon_issued" {
  domain      = var.certificate_domain_name
  types       = [local.cert_types]
  most_recent = true
}

data "aws_iam_policy_document" "jenkins_trust" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "jenkins" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = [
      "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetRandomPassword",
      "secretsmanager:ListSecrets"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:ListKeys"
    ]
    resources = ["arn:aws:kms:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:key/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:ListTasks",
      "ecs:ListTaskDefinitions",
      "ecs:ListServices",
      "ecs:ListClusters",
      "ecs:ListServices",
      "ecs:ListTaskDefinitionFamilies",
      "ecs:DescribeTaskDefinitions",
      "ecs:DeregisterTaskDefinition",
      "ecs:DiscoverPollEndpoint",
      "ecs:RegisterTaskDefinition",
      "ecs:CreateTaskSet",
      "ecs:DescribeTaskDefinition"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecs:CreateService",
      "ecs:ListTasks",
      "ecs:DeleteService",
      "ecs:ListTagsForResource",
      "ecs:ListContainerInstances",
      "ecs:DescribeTasks",
      "ecs:ListAttributes",
      "ecs:DescribeServices",
      "ecs:DescribeTaskSets",
      "ecs:DescribeContainerInstances",
      "ecs:DeleteAttributes",
      "ecs:DescribeClusters",
      "ecs:DeleteTaskSet",
      "ecs:DeregisterContainerInstance",
      "ecs:ExecuteCommand",
      "ecs:Poll",
      "ecs:PutAttributes",
      "ecs:RegisterContainerInstance",
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:StartTelemetrySession",
      "ecs:StopTask",
      "ecs:SubmitContainerStateChange",
      "ecs:SubmitTaskStateChange",
      "ecs:UpdateCluster",
      "ecs:UpdateClusterSettings",
      "ecs:UpdateContainerAgent",
      "ecs:UpdateContainerInstancesState",
      "ecs:UpdateService",
      "ecs:UpdateServicePrimaryTaskSet",
      "ecs:UpdateTaskSet",
      "ecs:TagResource",
      "ecs:UntagResource"
    ]
    resources = [
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:container-instance/*/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/*/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task/*/*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-definition/*:*",
      "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:task-set/*/*/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:BatchGetRepositoryScanningConfiguration",
      "ecr:BatchImportUpstreamImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeImageReplicationStatus",
      "ecr:DescribeImages",
      "ecr:DescribeRegistry",
      "ecr:DescribeRepositories",
      "ecr:GetAuthorizationToken",
      "ecr:GetDownloadUrlForLayer",
      "ecr:InitiateLayerUpload",
      "ecr:ListImages",
      "ecr:ListTagsForResource",
      "ecr:PutImage",
      "ecr:PutImageTagMutability",
      "ecr:PutReplicationConfiguration",
      "ecr:ReplicateImage",
      "ecr:StartImageScan",
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:UploadLayerPart"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:GetObjectAttributes",
      "s3:GetObjectVersion",
      "s3:ListAllMyBuckets",
      "s3:ListBucket",
      "s3:ListBucketVersions",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeImages",
      "ec2:DescribeTags",
      "ec2:DescribeSnapshots"
    ]
    resources = ["*"]
  }
}
