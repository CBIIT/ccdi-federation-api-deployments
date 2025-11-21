import boto3
import os
from configparser import ConfigParser
from constructs import Construct

import aws_cdk as cdk
from aws_cdk import Stack
from aws_cdk import RemovalPolicy
from aws_cdk import SecretValue
from aws_cdk import aws_elasticloadbalancingv2 as elbv2
from aws_cdk import aws_ec2 as ec2
from aws_cdk import aws_certificatemanager as cfm
from aws_cdk import aws_iam as iam
from aws_cdk import aws_s3 as s3
from aws_cdk import aws_ecr as ecr
from aws_cdk import aws_ecs as ecs
from aws_cdk import aws_efs as efs
from aws_cdk import aws_kms as kms
from aws_cdk import aws_secretsmanager as secretsmanager

class Stack(Stack):

    def __init__(self, scope: Construct, **kwargs) -> None:
        super().__init__(scope, **kwargs)

        # Read config file
        config = ConfigParser()
        config.read('config.ini')

        namingPrefix = "{}-{}".format(config['main']['resource_prefix'], config['main']['tier'])
        
        if config.has_option('main', 'subdomain'):
            self.app_url = "https://{}.{}".format(config['main']['subdomain'], config['main']['domain'])
        else:
            self.app_url = "https://{}".format(config['main']['domain'])

        # Import VPC
        vpc = ec2.Vpc.from_lookup(self, "VPC",
            vpc_id = config['main']['vpc_id']
        )
        
        # Secrets
        secret = secretsmanager.Secret(self, "Secret",
            secret_name= "ccdi/{}/federation/memgraph-db-creds".format(config['main']['tier']),
            secret_object_value={
                "db_user": SecretValue.unsafe_plain_text(config['db']['db_user']),
                "db_pass": SecretValue.unsafe_plain_text(config['db']['db_pass']),
            }
        )

        # EFS
        EFSSecurityGroup = ec2.SecurityGroup(self, "EFSSecurityGroup", vpc=vpc, allow_all_outbound=True,)
        EFSSecurityGroup.add_ingress_rule(peer=ec2.Peer.ipv4(vpc.vpc_cidr_block),
            connection=ec2.Port.tcp(2049),
            description="EFS"
        )

        # ECS Service Security Group
        ServiceSG = ec2.SecurityGroup(self, "ServiceSecurityGroup", vpc=vpc, allow_all_outbound=True, description="Security group for Memgraph ECS service")

        ServiceSG.add_ingress_rule(peer=ec2.Peer.any_ipv4(), 
            connection=ec2.Port.tcp(7687),
            description="Allow Memgraph traffic on port 7687"
        )

        ServiceSG.add_ingress_rule(peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.tcp(7444),
            description="Allow Memgraph traffic on port 7444"
        )

        fileSystem = efs.FileSystem(self, "EfsFileSystem",
            file_system_name="{}-memgraph".format(namingPrefix),
            vpc=vpc,
            encrypted=True,
            enable_automatic_backups=True,
            security_group=EFSSecurityGroup,
            removal_policy=RemovalPolicy.DESTROY
        )
        EFSAccessPoint = fileSystem.add_access_point("EFSAccessPoint",
            path="/{}".format(config['main']['tier']),
            create_acl=efs.Acl(
                owner_uid="101",
                owner_gid="101",
                permissions="755"
            ),
            posix_user=efs.PosixUser(
                uid="101",
                gid="101"
            )
        )

        # ECS Cluster
        kmsKey = kms.Key(self, "ECSExecKey")

        ECSCluster = ecs.Cluster(self,
            "ecs",
            cluster_name="{}-memgraph".format(namingPrefix),
            vpc=vpc,
            execute_command_configuration=ecs.ExecuteCommandConfiguration(
                kms_key=kmsKey
            )
        )

        # Fargate
        dbVolume = ecs.Volume(
            name="memgraph",
            efs_volume_configuration=ecs.EfsVolumeConfiguration(
                file_system_id=fileSystem.file_system_id,
                authorization_config=ecs.AuthorizationConfig(
                    access_point_id=EFSAccessPoint.access_point_id,
                    iam="ENABLED"
                ),
                transit_encryption="ENABLED"
            )
        )

        # configvolume = ecs.Volume(
        #     name="memgraph-config",
        #     efs_volume_configuration=ecs.EfsVolumeConfiguration(
        #         file_system_id=fileSystem.file_system_id,
        #         authorization_config=ecs.AuthorizationConfig(
        #             access_point_id=EFSAccessPoint.access_point_id,
        #             iam="ENABLED"
        #         ),
        #         transit_encryption="ENABLED"
        #     )
        # )

        taskDefinition = ecs.FargateTaskDefinition(self,
            "taskDef",
            family="{}-memgraph".format(namingPrefix),
            cpu=config.getint('ecs', 'cpu'),
            memory_limit_mib=config.getint('ecs', 'memory'),
            volumes=[dbVolume]#, configvolume]
        )
        dbContainer = taskDefinition.add_container("memgraph",
            image=ecs.ContainerImage.from_registry(config['ecs']['image']),
            cpu=config.getint('ecs', 'cpu'),
            memory_limit_mib=config.getint('ecs', 'memory'),
            #port_mappings=[ecs.PortMapping(container_port=config.getint('ecs', 'port'))],
            port_mappings=[
                ecs.PortMapping(container_port=7687),
                ecs.PortMapping(container_port=7444),
            ],
            #command = ["--data-directory=/usr/local/memgraph"],
            command=[
                 "--data-directory=/usr/local/memgraph",
                 "--log-level=TRACE",
                 "--also-log-to-stderr",
                 #"--schema-info-enabled=true",
                 #"--query-execution-timeout-sec=60000",
                 "--storage-mode=IN_MEMORY_ANALYTICAL"
            ],
            # command=["--config", "/etc/memgraph/memgraph.conf"],
            secrets={
                "MEMGRAPH_USER":ecs.Secret.from_secrets_manager(secret, 'db_user'),
                "MEMGRAPH_PASSWORD":ecs.Secret.from_secrets_manager(secret, 'db_pass')
            },
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="{}-memgraph".format(namingPrefix)
            )
        )
        containerVolumeMountPoint = ecs.MountPoint(
            read_only=False,
            container_path="/usr/local/memgraph",
            source_volume=dbVolume.name
        )
        # containerConfigVolumeMountPoint = ecs.MountPoint(
        #     read_only=False,
        #     container_path="/etc/memgraph",
        #     source_volume=configvolume.name
        # )
        dbContainer.add_mount_points(containerVolumeMountPoint)
        # dbContainer.add_mount_points(containerConfigVolumeMountPoint)
        fileSystem.grant_root_access(taskDefinition.task_role)

        ECSService = ecs.FargateService(self, "memgraphService",
            cluster=ECSCluster,
            service_name="{}-memgraph".format(namingPrefix),
            task_definition=taskDefinition,
            enable_execute_command=True,
            security_groups=[ServiceSG],
            min_healthy_percent=0,
            max_healthy_percent=100,
            circuit_breaker=ecs.DeploymentCircuitBreaker(
                enable=True,
                rollback=True
            )
        )

        # Load Balancer Security Group
        LBSecurityGroup = ec2.SecurityGroup(self, "NLBSecurityGroup", vpc=vpc, allow_all_outbound=True,)
        # Add ingress rule for port 7687
        LBSecurityGroup.add_ingress_rule(peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.tcp(config.getint('ecs', 'port')),
            description="bolt"
        )
        # Add ingress rule for port 7444
        LBSecurityGroup.add_ingress_rule(peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.tcp(7444),
            description="memgraph monitoring"
        )
        # Allow both ports from LB to ECS service
        ECSService.connections.security_groups[0].add_ingress_rule(
            LBSecurityGroup,
            ec2.Port.tcp(config.getint('ecs', 'port'))
        )
        ECSService.connections.security_groups[0].add_ingress_rule(
            LBSecurityGroup,
            ec2.Port.tcp(7444)
        )

        if config.getboolean('nlb', 'internet_facing'):
            subnets=ec2.SubnetSelection(
                subnets=vpc.select_subnets(one_per_az=True,subnet_type=ec2.SubnetType.PUBLIC).subnets
            )
        else:
            subnets=ec2.SubnetSelection(
                subnets=vpc.select_subnets(one_per_az=True,subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS).subnets
            )

        NLB = elbv2.NetworkLoadBalancer(self,
            "nlb",
            vpc=vpc,
            load_balancer_name=namingPrefix,
            internet_facing=config.getboolean('nlb', 'internet_facing'),
            vpc_subnets=subnets,
        )
        NLB.add_security_group(LBSecurityGroup)
        listener = NLB.add_listener("Listener", port=7687)
        nlbTargetGroup = elbv2.NetworkTargetGroup(self,
            id="nlbTargetGroup",
            target_type=elbv2.TargetType.IP,
            protocol=elbv2.Protocol.TCP,
            port=7687,
            vpc=vpc,
            health_check=elbv2.HealthCheck(
                port="7687",
                protocol=elbv2.Protocol.TCP
            )
        )
        listener.add_target_groups("target", nlbTargetGroup)
        nlbTargetGroup.add_target(ECSService)

        listener_7444 = NLB.add_listener("Listener7444", port=7444)
        nlbTargetGroup7444 = elbv2.NetworkTargetGroup(self,
            id="nlbTargetGroup7444",
            target_type=elbv2.TargetType.IP,
            protocol=elbv2.Protocol.TCP,
            port=7444,
            vpc=vpc,
            health_check=elbv2.HealthCheck(
                port="7444",
                protocol=elbv2.Protocol.TCP
            )
        )
        listener_7444.add_target_groups("target7444", nlbTargetGroup7444)
        nlbTargetGroup7444.add_target(ECSService)

        # --- Application Load Balancer ---
        # Public subnets (security rule) + Access logs to bucket/prefix from config
        if config.getboolean('alb', 'internet_facing'):
            subnets = ec2.SubnetSelection(
                subnets=vpc.select_subnets(one_per_az=True, subnet_type=ec2.SubnetType.PUBLIC).subnets
            )
        else:
            subnets = ec2.SubnetSelection(
                subnets=vpc.select_subnets(one_per_az=True, subnet_type=ec2.SubnetType.PRIVATE_WITH_EGRESS).subnets
            )
        
        ALB = elbv2.ApplicationLoadBalancer(
            self,
            "alb",
            vpc=vpc,
            internet_facing=config.getboolean("alb", "internet_facing", fallback=True),
            vpc_subnets=subnets
        )
        # ALB.add_redirect(
        #     source_protocol=elbv2.ApplicationProtocol.HTTP,
        #     source_port=80,
        #     target_protocol=elbv2.ApplicationProtocol.HTTPS,
        #     target_port=443
        # )

        client = boto3.client('acm')
        response = client.list_certificates(CertificateStatuses=['ISSUED'])

        for cert in response["CertificateSummaryList"]:
            if ('*.{}'.format(config['main']['domain']) in cert.values()):
                certARN = cert['CertificateArn']

        alb_cert = cfm.Certificate.from_certificate_arn(self, "alb-cert",
            certificate_arn=certARN)
        
        # self.listener = ALB.add_listener("PublicListener",
        #     certificates=[alb_cert],
        #     port=443
        # )

        # self.listener.add_action("ECS-Content-Not-Found",
        #     action=elbv2.ListenerAction.fixed_response(200,
        #         message_body="The requested resource is not available")
        # )

        ### ALB Access log
        log_bucket = s3.Bucket.from_bucket_name(self, "AlbAccessLogsBucket", config['main']['alb_log_bucket_name'])
        log_prefix = f"{config['main']['program']}/{config['main']['tier']}/{config['main']['project']}/alb-access-logs"

        ALB.log_access_logs(
            bucket=log_bucket,
            prefix=log_prefix
        )

        # REST API Task Definition and Container
        federationDCCRestApiTaskDefinition = ecs.FargateTaskDefinition(self,
            "federationDCCRestApiTaskDef",
            family="{}-federation-dcc-rest-api".format(namingPrefix),
            cpu=config.getint('federation_dcc_rest_api', 'cpu'),
            memory_limit_mib=config.getint('federation_dcc_rest_api', 'memory')
        )

        # Add required permissions to execution role
        federationDCCRestApiTaskDefinition.add_to_execution_role_policy(
            iam.PolicyStatement(
                effect=iam.Effect.ALLOW,
                actions=[
                    "ecr:GetAuthorizationToken",
                    "ecr:BatchCheckLayerAvailability",
                    "ecr:GetDownloadUrlForLayer",
                    "ecr:BatchGetImage",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ],
                resources=["*"]
            )
        )

        # use repository ARN to get IRepository
        ecr_repo = ecr.Repository.from_repository_arn(self, "federationDCCRestApi_repo", repository_arn=config['federation_dcc_rest_api']['repo'])

        # Federation REST API Service Security Group
        FederationDCCRestApiServiceSG = ec2.SecurityGroup(self, "FederationDCCRestApiServiceSecurityGroup", 
            vpc=vpc, 
            allow_all_outbound=True, 
            description="Security group for Federation DCC REST API ECS service"
        )

        FederationDCCRestApiServiceSG.add_ingress_rule(
            peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.tcp(config.getint('federation_dcc_rest_api', 'port')),
            description="Allow Federation DCC REST API traffic"
        )

        # create ContainerImage correctly from ECR repository
        federationDCCRestApi_image = ecs.ContainerImage.from_ecr_repository(ecr_repo, tag=config['federation_dcc_rest_api']['image'])

        federationDCCRestApiContainer = federationDCCRestApiTaskDefinition.add_container("federationDCCRestApi",
            image=federationDCCRestApi_image,
            cpu=config.getint('federation_dcc_rest_api', 'cpu'),
            memory_limit_mib=config.getint('federation_dcc_rest_api', 'memory'),
            port_mappings=[ecs.PortMapping(container_port=config.getint('federation_dcc_rest_api', 'port'))],
            environment={
                "memgraph_uri": "bolt://" + ALB.load_balancer_dns_name + ":7687",
                "memgraph_database": "memgraph"
            },
            secrets={
                "memgraph_user": ecs.Secret.from_secrets_manager(secret, 'db_user'),
                "memgraph_password": ecs.Secret.from_secrets_manager(secret, 'db_pass'),
                "federation_apis": ecs.Secret.from_secrets_manager(secret, 'federation_apis'),
                "federation_sources": ecs.Secret.from_secrets_manager(secret, 'federation_sources')
            },
            logging=ecs.LogDrivers.aws_logs(
                stream_prefix="{}-federation-dcc-rest-api".format(namingPrefix)
            )
        )

        federationDCCRestApiService = ecs.FargateService(self, "federationDCCRestApiService",
            cluster=ECSCluster,
            service_name="{}-federation-dcc-rest-api".format(namingPrefix),
            task_definition=federationDCCRestApiTaskDefinition,
            security_groups=[FederationDCCRestApiServiceSG],
            enable_execute_command=True,
            min_healthy_percent=0,
            max_healthy_percent=100,
            circuit_breaker=ecs.DeploymentCircuitBreaker(
                enable=True,
                rollback=True
            )
        )
        # Allow port from ALB to ECS service
        federationDCCRestApiService.connections.security_groups[0].add_ingress_rule(
            LBSecurityGroup,
            ec2.Port.tcp(config.getint('federation_dcc_rest_api', 'port'))
        )

        # federationDCCRestApiListener = ALB.add_listener("FederationDCCRestApiListener", 
        #     port=config.getint('federation_dcc_rest_api', 'port')
        # )

        federationDCCRestApiTargetGroup = elbv2.ApplicationTargetGroup(self,
            id="federationDCCRestApiTargetGroup",
            target_type=elbv2.TargetType.IP,
            protocol=elbv2.ApplicationProtocol.HTTP,
            port=config.getint('federation_dcc_rest_api', 'port'),
            vpc=vpc
        )

        # add_target_groups expects the target_groups argument as a keyword-only list
        # federationDCCRestApiListener.add_target_groups(
        #     "federationDCCRestApiTarget",
        #     target_groups=[federationDCCRestApiTargetGroup]
        # )
        federationDCCRestApiTargetGroup.add_target(federationDCCRestApiService)

        # Add ingress rule to LBSecurityGroup for Federation REST API port
        LBSecurityGroup.add_ingress_rule(
            peer=ec2.Peer.any_ipv4(),
            connection=ec2.Port.tcp(config.getint('federation_dcc_rest_api', 'port')),
            description="Federation DCC REST API"
        )