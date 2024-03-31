resource "aws_kms_key" "ecs_exec" {
  description         = "The AWS Key Management Service key that encrypts the data between the local client and the container"
  enable_key_rotation = true
}


