locals {
  app                      = "ins"
  permission_boundary_arn  = terraform.workspace == "nonprod" ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/PermissionBoundary_PowerUser" : null
  nih_cidrs                = ["129.43.0.0/16", "137.187.0.0/16", "10.128.0.0/9", "165.112.0.0/16", "156.40.0.0/16", "10.208.0.0/21", "128.231.0.0/16", "130.14.0.0/16", "157.98.0.0/16", "10.133.0.0/16"]
  public_service_endpoints = ["0.0.0.0/0"]
  ipv6_all                 = ["::/0"]
  vpc_id                   = terraform.workspace == "nonprod" ? "vpc-29a12251" : "vpc-c29e1dba"
  level                    = terraform.workspace
}