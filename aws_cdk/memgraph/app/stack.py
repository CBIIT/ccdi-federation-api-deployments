import os
from configparser import ConfigParser
from constructs import Construct

from aws_cdk import Stack
from aws_cdk import RemovalPolicy
from aws_cdk import SecretValue
from aws_cdk import aws_elasticloadbalancingv2 as elbv2
from aws_cdk import aws_ec2 as ec2
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
        
        # Import VPC
        vpc = ec2.Vpc.from_lookup(self, "VPC",
            vpc_id = config['main']['vpc_id']
        )
        
        # Secrets
        secret = secretsmanager.Secret(self, "Secret",
            secret_name= "ccdi/nonprod/federation/memgraph-db-creds",
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
            port=config.getint('ecs', 'port'),
            vpc=vpc
        )
        listener.add_target_groups("target", nlbTargetGroup)
        nlbTargetGroup.add_target(ECSService)

        listener_7444 = NLB.add_listener("Listener7444", port=7444)
        nlbTargetGroup7444 = elbv2.NetworkTargetGroup(self,
            id="nlbTargetGroup7444",
            target_type=elbv2.TargetType.IP,
            protocol=elbv2.Protocol.TCP,
            port=7444,
            vpc=vpc
        )
        listener_7444.add_target_groups("target7444", nlbTargetGroup7444)
        nlbTargetGroup7444.add_target(ECSService)