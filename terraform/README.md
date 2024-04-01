# To-Do:
1. Check to make sure the central_ecr_account_id given to the ECS module is properly sourced.
2. Determine what the desired URL will be for the API - and check if an ACM certificate exists that will support the URL. 


# Review Outcomes


# General Review:
1. Removed databases, cloudfront, and S3 snapshot bucket from the main.tf file as those are not used in the system stack.
2. Deleted the s3.tf file as the current resources defined in that file are not required for this stack.

# Variables Review:
1. set a default value for program and project variables. 
2. Removed the private_subnet_ids variable - need to ensure we are more specific and choosing the private webapp subnets, not the private subnets in general.
3. Removed cmb_microservices variable as it is not used in the system stack.
4. Removed the target_account_cloudone variable as it is not used in the system stack.
5. Removed lb_type variable as we aren't required to set it at the module (the module has a default).
6. Removed the internal_alb variable as we are conditionally setting this with terraform.workspace conditionals for the ALB module.
7. Removed s3_opensearch_snapshot_bucket variable as it is not used in the system stack.
8. Removed rds_username variable as it is not used in the system stack.
9. Removed rds_instance_class variable as it is not used in the system stack.
10. Removed create_rds_security_group variable as it is not used in the system stack.
11. Removed create_rds_db_subnet_group variable as it is not used in the system stack.
12. Removed rds_allocated_storage variable as it is not used in the system stack.
13. Removed create_rds_mysql variable as it is not used in the system stack.
14. Removed aws_prod_account_id variable as it should not be used in the terraform stack as a variable for now unless it is needed (unlikely).
15. Removed aws_nonprod_account_id variable as it should not be used in the terraform stack as a variable for now unless it is needed (unlikely).
16. Removed aws_account_id variable as we can use a data source if needed.
17. Removed opensearch_version variable as it is not used in the system stack.
18. Removed opensearch_instance_type variable as it is not used in the system stack.
19. Removed opensearch_instance_count variable as it is not used in the system stack.
20. Removed opensearch_instance_volume_size variable as it is not used in the system stack.
21. Removed multi_az_enabled variable as it is not used in the system stack.
22. Removed create_os_service_role variable as it is not used in the system stack.
23. Removed create_cloudwatch_log_policy variable as it is not used in the system stack.
24. Removed automated_snapshot_start_hour variable as it is not used in the system stack.
25. Removed alarms variable as it is not used in the system stack. 
26. Removed cloudfront_distribution_bucket_name variable as it is not used in the system stack.
27. Removed cloudfront_log_path_prefix_key variable as it is not used in the system stack.
28. Removed cloudfront_origin_acess_identity_description variable as it is not used in the system stack.
29. Removed cloudfront_slack_channel_name variable as it is not used in the system stack.
30. Removed create_cloudfront variable as it is not used in the system stack.
31. Removed create_files_bucket variable as it is not used in the system stack.
32. Removed slack_secret_name variable as it is not used in the system stack (for now).
33. Removed create_ecr_repos as the creation of ECR repositories happens in the central ECR managed by a different repository.
34. Removed create_env_specific_repo as the creation of ECR repositories happens in the central ECR managed by a different repository.
35. Removed ecr_repo_names as the creation of ECR repositories happens in the central ECR managed by a different repository.
36. Removed aws_region variable as it is not used in the system stack, and rather is set by a data source.
37. Removed add_opensearch_permission variable as it is not used in the system stack.
38. Removed public_subnet_ids as these are sourced from a data source.
39. Removed create_db_instance as it is not used in the system stack.
40. Removed create_opensearch_cluster as it is not used in the system stack.

## ECS Review:
1. Updated module to use v1.16 (latest as of 4/1/24)
2. Alphabetized the module arguments for readability. 
3. Updated the ecs_subnet_ids to use the data source for appropriate subnets.
4. Removed the add_opensearch_permission argument as the module defaults the value to false and opensearch is not needed for the system stack.
5. Updated the VPC ID argument to use the data source for the appropriate VPC.
6. Removed add_cloudwatch_stream because the variable is not used in the module, though the module has the variable set with a default. 
7. Removed the target_account_cloudone argument as the module defaults the value to true. 

## ALB Reiview:
1. Updated module to use v1.16 (latest as of 4/1/24)
2. Alphabetized the module arguments for readability.
3. Removed the alb_type argument as the module defaults to "application", which is what we want.
4. Updated the ALB subnets to use the data sources, accounting for the fact that the dev tier does not have a set of public subnets.
5. Updated the alb_internal argument to conditionally set the value based on tier.
6. Updated the VPC ID argument to use the data source for the appropriate VPC.

## Data Source Review:
1. created a vpc data source that depends on the terraform.workspace value, deleted the vpc_id variable, and modified resources previously using the vpc_id variable to use the vpc data source.
2. Created data sources for subnets that depends on the terraform.workspace value. 
3. Removed opensearch from the instance profile trust policy used by EC2 (Jenkins)
4. Removed aws_iam_role_policy_attachment.s3_opensearch_cross_account_access as it is not used in the system stack.
5. Removed aws_iam_policy_document.s3_opensearch_cross_account_access_policy_document as it is not used in the system stack.
6. Removed all opensearch snapshot role/policy/attachment resources as they are not used in the system stack.
7. Removed unnecessary S3 bucket policy definition that appeared to be used for alb logging - that's handled by the module.
8. Established ACM certificate data source to get the imported certificate ARN for the ALB.

## S3 Review:
1. Removed aws_s3_bucket_policy.s3_snapshot_policy as it's not being used by the stack. 

## Security Group Review:
1. Removed aws_security_group_rule.mysql_inbound as it's not required for the stack.
2. Removed aws_security_group_rule.opensearch_outbound as it's not required for the stack.
3. Removed aws_security_group_rule.opensearch_inbound as it's not required for the stack.
4. Updated ECS ingress rule to only allow traffic originating from the ALB security group.

## Locals Review:
1. Removed the http port local value as its redundant to treat this as a local. 
2. Removed the https port local value as its redundant to treat this as a local.
3. Removed the tcp_protocol local value as its redundant to treat this as a local.
4. Removed mysql_port local value as it is not used in the system stack.
5. removed neo4j_http local value as it is not used in the system stack.
6. Removed neo4j_https local value as it is not used in the system stack.
7. Removed neo4j_bolt local value as it is not used in the system stack.
8. Removed bastion_port local value as it is not used in the system stack.
9. Removed any_port local value as its redundant to treat this as a local.
10. Removed any_protocol local value as its redundant to treat this as a local.
11. Removed allowed_alb_ip_range local value as it just points to another local value in the same file
12. Removed all_ips local value as its redundant to treat this as a local.
13. Removed nih_ip_cidrs local value as this was incorrectly set.
14. Removed alb_subnet_ids local value as this value is set directly in the module. 
15. Removed the alb_log_bucket_name as this is set by the ALB module itself as a default.
16. Removed cert_types local value as its redundant to treat this as a local.
17. Removed resource_prefix local value as this is handled by a variable already.
18. Removed s3_snapshot_bucket_name local value as it is not used in the system stack.
19. Updated the application_url local to reflect appropriate values for this project, based on tier

# Instance Profile Review:
1. Renamed the instance profiile role to be shorter so that AWS doesn't complain about the length of the role name.
2. Updated conditionals to only create the instance profile if the tier is  dev or stage.
3. Removed the managed ECR policy from the instance profile since those permissions are already defined in the custom Jenkins policy we define.
4. Removed the iam:PassRole and iam:GetRole permissions from Jenkins role since it is not required for this stack.
6. Removed the opensearch permissions from the Jenkins policy as it is not required for this stack.
7. Removed the RDS permissions from the Jenkins policy as it is not required for this stack.
8. Removed the unrestricted secrets manager permissions from the Jenkins policy to improve security by design.

## Outputs Review:
1. Removed the opensearch_endpoint output as it is not used in the system stack.
2. Deleted the outputs.tf file as it is not used for now.

## Provider Review:
1. Added us-east-1 as the region for the provider.