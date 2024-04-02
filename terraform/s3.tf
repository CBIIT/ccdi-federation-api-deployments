resource "aws_s3_bucket" "kinesis" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  bucket = "${var.program}-${local.account_level}-${var.project}-kinesis-log-failures"
}

resource "aws_s3_bucket_public_access_block" "kinesis" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  bucket                  = aws_s3_bucket.kinesis[0].bucket
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "kinesis" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  bucket = aws_s3_bucket.kinesis[0].id
  policy = data.aws_iam_policy_document.kinesis[0].json
}

data "aws_iam_policy_document" "kenisis" {
  count = terraform.workspace == "dev" || terraform.workspace == "stage" ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.kinesis[0].arn}",
      "${aws_s3_bucket.kinesis[0].arn}/*"
    ]
  }
}
