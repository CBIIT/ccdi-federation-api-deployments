import boto3
import requests
import argparse
import logging
from requests_aws4auth import AWS4Auth

logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Creating a session for boto3 to retrieve the region and credentials
session = boto3.session.Session()

# Configuring an arg parser
parser = argparse.ArgumentParser(
    description="Creates OpenSearch Snapshots and Registers Repositories"
)
parser.add_argument(
    "--host",
    type=str,
    help="OpenSearch host beginning with https and trailing with /",
    required=True,
)

parser.add_argument(
    "--roleArn",
    type=str,
    help="AWS Role ARN OpenSearch will assume for Snapshot Operations",
    required=True,
)

parser.add_argument(
    "--s3bucket",
    type=str,
    help="Name of the S3 Bucket that Stores Snapshots, required=True",
    required=True,
)

parser.add_argument(
    "--s3Path",
    type=str,
    help="The Path within the S3 Bucket that Stores Snapshots",
    default="snapshots",
    required=False,
)

parser.add_argument(
    "--snapshotName",
    type=str,
    help="The name provided to the actual snapshot",
    required=True,
)

parser.add_argument(
    "--repositoryName",
    type=str,
    help="The name provided to the repository that stores the snapshot",
    required=True,
)

args = parser.parse_args()


host = args.host
region = session.region_name
service = "es"
repositoryName = args.repositoryName
roleArn = args.roleArn
snapshotName = args.snapshotName
s3Bucket = args.s3bucket
s3Path = args.s3Path
repositoryPath = host + "_snapshot/" + repositoryName
snapshotPath = host + "_snapshot/" + repositoryName + "/" + snapshotName


# Creating an AWS4Auth object for the requests library
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    service,
    session_token=credentials.token,
)


headers = {"Content-Type": "application/json"}
payload = {
    "type": "s3",
    "settings": {
        "bucket": s3Bucket,
        "base_path": s3Path,
        "canned_acl": "bucket-owner-full-control",
        "region": region,
        "role_arn": roleArn,
    },
}


def repositoryExists(repositoryPath, awsauth, headers):
    r = requests.get(repositoryPath, auth=awsauth, headers=headers)
    if r.status_code == 200:
        logger.info("The snapshot repository already exists. No need to register it.")
        return True
    else:
        logger.info(
            "The snapshot repository does not exist. Must register a new repository."
        )
        return False


def registerRepository(repositoryPath, awsauth, headers, payload):
    try:
        logger.info("Registering repository now")
        r = requests.put(repositoryPath, auth=awsauth, json=payload, headers=headers)
        response = {
            "status_code": r.status_code,
            "response": r.text,
        }
        return response
    except Exception as e:
        raise Exception("Failed to register repository - " + e)


def createSnapshot(snapshotPath, awsauth, headers, payload):
    try:
        logger.info("Creating snapshot now")
        r = requests.put(snapshotPath, auth=awsauth, json=payload, headers=headers)
        response = {
            "status_code": r.status_code,
            "response": r.text,
        }
        return response
    except Exception as e:
        raise Exception("Failed to create snapshot - " + e)


def main():
    if repositoryExists(repositoryPath, awsauth, headers):
        try:
            logger.info("Repository already exists")
            logger.info("Creating snapshot now")
            response = createSnapshot(snapshotPath, awsauth, headers, payload)
            return response
        except Exception as e:
            raise Exception("Failed to create snapshot - " + e)
    else:
        try:
            response = registerRepository(repositoryPath, awsauth, headers, payload)
            response = createSnapshot(snapshotPath, awsauth, headers, payload)
            return response
        except Exception as e:
            raise Exception("Failed to register repository  - " + e)


if __name__ == "__main__":
    main()
