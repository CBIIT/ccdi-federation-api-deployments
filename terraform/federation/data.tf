#################################################################################################
## Account Resources ############################################################################
#################################################################################################

data "aws_caller_identity" "current" {

}

#################################################################################################
## Certificate Resources ########################################################################
#################################################################################################

data "aws_acm_certificate" "domain" {
  domain = "*.cancer.gov"
}

#################################################################################################
## VPC Resources ################################################################################
#################################################################################################

data "aws_vpc" "vpc" {

  filter {
    name   = "tag:Name"
    values = ["*${terraform.workspace}*"]
  }
}

#################################################################################################
## Subnet Resources #############################################################################
#################################################################################################

data "aws_subnets" "public" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "sn-${terraform.workspace}-dm*-ext-us-east-1*"
  }
}


data "aws_subnets" "webapp" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "sn-${terraform.workspace}-webapp-us-east-1*"
  }
}


data "aws_subnets" "database" {

  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.vpc.id]
  }

  tags = {
    Name = "sn-${terraform.workspace}-db-us-east-1*"
  }
}

data "aws_iam_policy_document" "ecs_trust_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# combine several below policies to define the task_execution_role (keeping things modular)
data "aws_iam_policy_document" "ecs_task_execution_role_policy_doc" {
  source_policy_documents = [
    data.aws_iam_policy_document.task_execution_ecr.json,
    data.aws_iam_policy_document.task_execution_secrets.json,
    data.aws_iam_policy_document.task_execution_kms.json,
    data.aws_iam_policy_document.ecs_exec_cloudwatch.json,
  ]
}

data "aws_iam_policy_document" "task_execution_kms" {
  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = ["arn:aws:kms:us-east-1:${data.aws_caller_identity.current.account_id}:key/*"]
  }
}

data "aws_iam_policy_document" "task_execution_secrets" {
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:ListSecrets",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:GetResourcePolicy"
    ]
    resources = ["arn:aws:secretsmanager:us-east-1:${data.aws_caller_identity.current.account_id}:secret:*"]
  }
}

data "aws_iam_policy_document" "task_execution_ecr" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutImage",
      "ecr:CompleteLayerUpload",
      "ecr:DescribeRepositories",
      "ecr:GetLifecyclePolicy",
      "ecr:GetRepositoryPolicy",
      "ecr:InitiateLayerUpload",
      "ecr:ListTagsForResource",
      "ecr:UploadLayerPart"
    ]
    resources = ["arn:aws:ecr:us-east-1:${data.aws_caller_identity.current.account_id}:repository/*","arn:aws:ecr:us-east-1:986019062625:repository/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "ecs_exec_cloudwatch" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:DescribeLogGroup",
      "logs:DescribeLogStream",
      "logs:CreateLogGroup"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
    ]
  }
}

# combine all policy docs defined below for the task_role (keeping things modular)

data "aws_iam_policy_document" "ecs_task_role_exec_policy_doc" {
  source_policy_documents = [
    data.aws_iam_policy_document.ecs_exec_command.json,
    data.aws_iam_policy_document.task_execution_ecr.json,
    data.aws_iam_policy_document.ecs_exec_cloudwatch.json,
    data.aws_iam_policy_document.ecs_exec_kms.json,
    data.aws_iam_policy_document.task_execution_secrets.json,
    data.aws_iam_policy_document.os_policy.json,
    data.aws_iam_policy_document.ecs_exec_ssm.json
  ]
}

data "aws_iam_policy_document" "ecs_exec_command" {
  statement {
    effect    = "Allow"
    actions   = ["ecs:ExecuteCommand"]
    resources = [aws_ecs_cluster.ecs_cluster.arn]
  }
}

data "aws_iam_policy_document" "ecs_exec_kms" {

  statement {
    effect = "Allow"
    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey"
    ]
    resources = [aws_kms_key.ecs_exec.arn]
  }

}

data "aws_iam_policy_document" "ecs_exec_ssm" {

  statement {
    effect = "Allow"
    actions = [
      "ssmmessages:CreateControlChannel",
      "ssmmessages:CreateDataChannel",
      "ssmmessages:OpenControlChannel",
      "ssmmessages:OpenDataChannel"
    ]
    resources = ["*"]
  }

}

data "aws_iam_policy_document" "os_policy" {
  statement {
    effect    = "Allow"
    actions   = ["es:ESHttp*"]
    resources = ["${module.opensearch.opensearch_arn}/*"]
  }
}

data "aws_iam_policy_document" "neo4j_server_assume_role" {
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

data "aws_iam_policy_document" "neo4j_server_policy" {

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
}


# data "aws_iam_policy_document" "ecs_policy_doc" {

#   statement {
#     effect    = "Allow"
#     actions   = ["ecs:*"]
#     resources = ["arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:cluster/${local.ecs_cluster_name}"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "ecr:BatchGetImage",
#       "ecr:GetDownloadUrlForLayer",
#       "ecr:GetAuthorizationToken",
#       "ecr:BatchCheckLayerAvailability",
#       "ecr:PutImage",
#       "ecr:CompleteLayerUpload",
#       "ecr:DescribeRepositories",
#       "ecr:GetLifecyclePolicy",
#       "ecr:GetRepositoryPolicy",
#       "ecr:InitiateLayerUpload",
#       "ecr:ListTagsForResource",
#       "ecr:UploadLayerPart"
#     ]
#     resources = ["arn:aws:ecr:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:repository/*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "es:ESHttpDelete",
#       "es:ESHttpGet",
#       "es:ESHttpHead",
#       "es:ESHttpPost",
#       "es:ESHttpPut",
#       "es:ESHttpPatch"
#     ]
#     resources = ["arn:aws:es:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:domain/${var.app}-opensearch-${terraform.workspace}/*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:GetObjectVersion",
#       "s3:PutObject",
#       "s3:ListBucket",
#       "s3:ListMultipartUploadParts"
#     ]
#     resources = [
#       aws_s3_bucket.logs.arn,
#     "${aws_s3_bucket.logs.arn}/*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "secretsmanager:GetResourcePolicy",
#       "secretsmanager:GetSecretValue",
#       "secretsmanager:DescribeSecret",
#       "secretsmanager:ListSecretVersionIds",
#       "secretsmanager:ListSecrets"
#     ]
#     resources = [aws_secretsmanager_secret_version.secret.arn]
#   }
# }

# data "aws_iam_policy_document" "opensearch_snapshot_policy" {
#   statement {
#     effect    = "Allow"
#     actions   = ["s3:ListBucket"]
#     resources = ["arn:aws:s3:::mtp*"]
#   }

#   statement {
#     effect = "Allow"
#     actions = [
#       "s3:GetObject",
#       "s3:PutObject",
#       "s3:DeleteObject"
#     ]
#     resources = ["arn:aws:s3:::mtp*"]
#   }
# }

# data "aws_iam_policy_document" "opensearch_snapshot_assume_role_policy" {
#   statement {
#     effect  = "Allow"
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["opensearchservice.amazonaws.com"]
#     }
#   }
# }

# data "aws_iam_policy_document" "cloudwatch" {
# statement {
#   effect = "Allow"
#   principals {
#     type        = "Service"
#     identifiers = ["es.amazonaws.com"]
#   }
#   actions = [
#     "logs:PutLogEvents",
#     "logs:PutLogEventsBatch",
#     "logs:CreateLogStream"
#   ]
#   resources = ["arn:aws:logs:*"]
# }
# }
/*
data "aws_iam_policy_document" "os" {
  statement {
    effect = "Allow"
    actions = [
      "es:ESHttpPut",
      "es:ESHttpPost",
      "es:ESHttpPatch",
      "es:ESHttpHead",
      "es:ESHttpGet",
      "es:ESHttpDelete"
    ]
    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
    resources = ["${aws_opensearch_domain.os.arn}/*"]
  }
}
**/
#################################################################################################
## S3 snapshot bucket ########################################################################
#################################################################################################

data "aws_iam_policy_document" "s3bucket_policy" {
  count  = terraform.workspace == "stage" ? 1 : 0
  statement {
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root",
            "arn:aws:iam::${lookup(var.aws_nonprod_account_id,var.region,"us-east-1" )}:root",
        ]
      }
      actions = [
        "s3:ListBucket",
        "s3:GetObject",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:ListBucketVersions",
        "s3:GetObjectVersion"
      ]
      resources = [
        "arn:aws:s3:::${module.s3_opensearch_snapshot[0].bucket_name}",
        "arn:aws:s3:::${module.s3_opensearch_snapshot[0].bucket_name}/*"
      ]
    }
}

#################################################################################################
## Opensearch snapshot policy ###################################################################
#################################################################################################

data "aws_iam_policy_document" "trust" {
  count     = terraform.workspace == "dev" || terraform.workspace == "stage"  ? 1 : 0
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["es.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "opensearch_snapshot_role" {
  count                 = terraform.workspace == "dev" || terraform.workspace == "stage"  ? 1 : 0
  name                  = "power-user-${var.program}-${terraform.workspace}-${var.app}-opensearch-snapshot"
  assume_role_policy    = data.aws_iam_policy_document.trust[0].json
  description           = "role that allows the opensearch service to create snapshots stored in s3"
  force_detach_policies = false
  permissions_boundary  = local.permission_boundary_arn
}

resource "aws_iam_policy" "opensearch_snapshot_policy" {
  count       = terraform.workspace == "dev" || terraform.workspace == "stage"  ? 1 : 0
  name        = "power-user-${var.program}-${terraform.workspace}-${var.app}-opensearch-snapshot"
  description = "role that allows the opensearch service to create snapshots stored in s3"
  policy      = data.aws_iam_policy_document.opensearch_snapshot_policy_document[0].json
}

data "aws_iam_policy_document" "opensearch_snapshot_policy_document" {
  count     = terraform.workspace == "dev" || terraform.workspace == "stage"  ? 1 : 0
  statement {
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_opensearch_snapshot_bucket}",]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_opensearch_snapshot_bucket}",
      "arn:aws:s3:::${var.s3_opensearch_snapshot_bucket}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
      "iam:GetRole"
    ]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/power-user*"]
  }

  statement {
    effect = "Allow"
    actions = ["es:*"]
    resources = [ "arn:aws:es:us-east-1:${data.aws_caller_identity.current.account_id}:domain/*" ]
  }
}

resource "aws_iam_role_policy_attachment" "opensearch_snapshot_policy_attachment" {
  count     = terraform.workspace == "dev" || terraform.workspace == "stage"  ? 1 : 0
  role       = aws_iam_role.opensearch_snapshot_role[0].name
  policy_arn = aws_iam_policy.opensearch_snapshot_policy[0].arn
}

#################################################################################################
## role for cross account access ################################################################
#################################################################################################

data "aws_iam_policy_document" "cross_account_trust" {
  count     = terraform.workspace == "stage" ? 1 : 0
  statement {
    effect = "Allow"

    principals {
    	  identifiers = ["arn:aws:iam::${lookup(var.aws_nonprod_account_id,var.region,"us-east-1" )}:root"]
          type        = "AWS"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "s3_opensearch_cross_account_access_role" {
  count                 = terraform.workspace == "stage" ? 1 : 0
  name                  = "power-user-${var.program}-${terraform.workspace}-${var.app}-s3-opensearch-cross-account-access"
  assume_role_policy    = data.aws_iam_policy_document.cross_account_trust[0].json
  description           = "role that allows the opensearch service to access prod s3"
  force_detach_policies = false
}

resource "aws_iam_policy" "s3_opensearch_cross_account_access_policy" {
  count       = terraform.workspace == "stage" ? 1 : 0
  name        = "power-user-${var.program}-${terraform.workspace}-${var.app}-s3-opensearch-cross-account-access"
  description = "role that allows the opensearch service to access prod s3"
  policy      = data.aws_iam_policy_document.s3_opensearch_cross_account_access_policy_document[0].json
}

data "aws_iam_policy_document" "s3_opensearch_cross_account_access_policy_document" {
  count     = terraform.workspace == "stage" ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_opensearch_snapshot_bucket}",
      "arn:aws:s3:::${var.s3_opensearch_snapshot_bucket}/*"
    ]
  }
}

resource "aws_iam_role_policy_attachment" "s3_opensearch_cross_account_access" {
  count                 = terraform.workspace == "stage" ? 1 : 0
  role                  = aws_iam_role.s3_opensearch_cross_account_access_role[0].name
  policy_arn            = aws_iam_policy.s3_opensearch_cross_account_access_policy[0].arn
}