data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "integration_server_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type = "Service"
      identifiers = [
        "ec2.amazonaws.com",
        "opensearchservice.amazonaws.com"
      ]
    }
  }
}

data "aws_iam_policy_document" "integration_server_policy" {
  statement {
    effect = "Allow"
    actions = [
      "iam:GetRole"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/power-user-*",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ins-*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
      "kms:Encrypt",
      "kms:ListKeys",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/*"]
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
      "ecs:DeregisterContainerInstance",
      "ecs:ExecuteCommand",
      "ecs:Poll",
      "ecs:PutAttributes",
      "ecs:RegisterContainerInstance",
      "ecs:RunTask",
      "ecs:StartTask",
      "ecs:StopTask",
      "ecs:SubmitContainerStateChange",
      "ecs:SubmitTaskStateChange",
      "ecs:UpdateCluster",
      "ecs:UpdateClusterSettings",
      "ecs:UpdateContainerAgent",
      "ecs:UpdateContainerInstancesState",
      "ecs:UpdateService",
      "ecs:TagResource",
      "ecs:UntagResource"
    ]
    resources = [
      "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:cluster/*",
      "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:container-instance/*/*",
      "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:service/*/*",
      "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:task/*/*",
      "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:task-definition/*:*",
      "arn:aws:ecs:us-east-1:${data.aws_caller_identity.current.account_id}:task-set/*/*/*"
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
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage"
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
      "secretsmanager:CreateSecret",
      "secretsmanager:DescribeSecret",
      "secretsmanager:GetRandomPassword",
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets",
      "secretsmanager:PutSecretValue",
      "secretsmanager:RestoreSecret"
    ]
    resources = ["arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "es:ESHttpDelete",
      "es:ESHttpGet",
      "es:ESHttpHead",
      "es:ESHttpPatch",
      "es:ESHttpPost",
      "es:ESHttpPut"
    ]
    resources = [
      "arn:aws:es:us-east-1:${data.aws_caller_identity.current.account_id}:domain/ccdi-ins-*"
    ]
  }
}
