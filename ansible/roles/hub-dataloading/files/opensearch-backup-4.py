import boto3
import requests
import logging
import argparse
from requests_aws4auth import AWS4Auth

logging.basicConfig(level=logging.INFO)


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

parser.add_argument(
    "--region",
    type=str,
    help="The region of the OpenSearch domain",
    default="us-east-1",
    required=False,
)

args = parser.parse_args()


headers = {"Content-Type": "application/json"}
s3Path = "snapshots/" + args.repositoryName + "/" + args.snapshotName
repositoryPath = args.host + "_snapshot/" + args.repositoryName
snapshotPath = args.host + "_snapshot/" + args.repositoryName + "/" + args.snapshotName

payload = {
    "type": "s3",
    "settings": {
        "bucket": args.s3bucket,
        "region": args.region,
        "canned_acl": "bucket-owner-full-control",
        "role_arn": args.roleArn,
        "base_path": s3Path,
    },
}

params = {
    "region": args.region,
    "service": "es",
    "repositoryName": args.repositoryName,
    "snapshotName": args.snapshotName,
    "host": args.host,
    "s3Path": s3Path,
    "repositoryPath": repositoryPath,
    "snapshotPath": snapshotPath,
    "headers": headers,
    "payload": payload,
}


def parseExistingRepositoryResponse(statusCode):
    if statusCode == 200:
        statusMessage = "......the repository already exists!"
        logging.info(statusMessage)
        return statusCode, statusMessage
    elif statusCode == 404:
        statusMessage = "......the repository does not exist. queuing registration"
        logging.info(statusMessage)
        return statusCode, statusMessage
    else:
        statusMessage = "......an error occured while checking if the repository exists"
        logging.error(statusMessage)
        return statusCode, statusMessage


def checkExistingRepositories(params, awsauth):
    path = params["repositoryPath"]
    headers = params["headers"]

    try:
        logging.info("Checking if the repository exists...")
        r = requests.get(path, auth=awsauth, headers=headers)
        statusCode, statusMessage = parseExistingRepositoryResponse(r.status_code)
        return statusCode, statusMessage
    except requests.exceptions.RequestException as e:
        raise e


def parseCreateRepositoryResponse(statusCode):
    if statusCode == 200:
        statusMessage = "......created a new repository"
        logging.info(statusMessage)
        return statusCode, statusMessage
    else:
        statusMessage = "......an error occured while creating the repository"
        logging.error(statusMessage)
        return statusCode, statusMessage


def createRepository(params, awsauth):
    path = params["repositoryPath"]
    headers = params["headers"]
    payload = params["payload"]

    try:
        r = requests.put(path, auth=awsauth, headers=headers, json=payload)
        statusCode, statusMessage = parseCreateRepositoryResponse(r.status_code)
        return statusCode, statusMessage
    except requests.exceptions.RequestException as e:
        raise e


def registerRepository(statusCode, params, awsauth):
    if statusCode == 200:
        statusMessage = "......skipping repository registration"
        logging.info(statusMessage)
        return statusCode, statusMessage
    elif statusCode == 404:
        logging.info("......trying to register the new repository")
        statusCode, statusMessage = createRepository(params, awsauth)
        return statusCode, statusMessage
    else:
        logging.error("......an error occured while registering the repository")
        return statusCode, statusMessage


def parseCreateSnapshotResponse(statusCode):
    if statusCode == 200:
        statusMessage = "......successfully created a new snapshot"
        logging.info(statusMessage)
        return statusCode, statusMessage
    else:
        statusMessage = "......an error occured while creating the snapshot"
        logging.error(statusMessage)
        return statusCode, statusMessage


def createSnapshot(params, awsauth):
    path = params["snapshotPath"]

    try:
        logging.info("Creating the snapshot...")
        r = requests.put(path, auth=awsauth)
        statusCode, statusMessage = parseCreateSnapshotResponse(r.status_code)
        return statusCode, statusMessage
    except requests.exceptions.RequestException as e:
        raise e


def main(params):
    logging.info("Starting OpenSearch Snapshot Process...")
    logging.info("Building the AWS Auth Object...")

    region = params["region"]
    service = params["service"]

    credentials = boto3.Session().get_credentials()
    awsauth = AWS4Auth(
        credentials.access_key,
        credentials.secret_key,
        region,
        service,
        session_token=credentials.token,
    )

    statusCode, statusMessage = checkExistingRepositories(params, awsauth)
    statusCode, statusMessage = registerRepository(statusCode, params, awsauth)
    statusCode, statusMessage = createSnapshot(params, awsauth)

    logging.info("OpenSearch Snapshot Process Complete")


if __name__ == "__main__":
    main(params)
