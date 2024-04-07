import boto3
import requests
import logging
import argparse
from requests_aws4auth import AWS4Auth

logging.basicConfig(level=logging.INFO)

##################################################################
# Step 1: Parse command-line arguments ###########################
##################################################################

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
logging.info("Arguments have been parsed: " + str(args))

##################################################################
# Step 2: Set Environment Variables ##############################
##################################################################

# Parsed Variables
host = args.host
roleArn = args.roleArn
region = args.region
service = "es"
repositoryName = args.repositoryName
snapshotName = args.snapshotName
s3Bucket = args.s3bucket
headers = {"Content-Type": "application/json"}

# Constructed Variables
s3Path = (
    "snapshots/" + repositoryName + "/" + snapshotName
)  # PAY ATTENTION TO THIS! snapshots/v1.0.2/1

repositoryPath = host + "_snapshot/" + repositoryName
snapshotPath = host + "_snapshot/" + repositoryName + "/" + snapshotName

payload = {
    "type": "s3",
    "settings": {
        "bucket": s3Bucket,
        "region": region,
        "canned_acl": "bucket-owner-full-control",
        "role_arn": roleArn,
        "base_path": s3Path,
    },
}

##################################################################
# Step 3: Create AWS4Auth Object #################################
##################################################################

logging.info("Creating AWS4Auth object...")
session = boto3.session.Session()

credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(
    credentials.access_key,
    credentials.secret_key,
    region,
    service,
    session_token=credentials.token,
)

logging.info("AWS4Auth object has been created")


##################################################################
# Step 4: Check if the Repository Exists #########################
##################################################################

try:
    logging.info("Checking if the repository exists...")
    repo_exists = requests.get(repositoryPath, auth=awsauth, headers=headers)
    logging.info("After checking if the repository exists...")
    logging.info("Status code for repository check: " + str(repo_exists.status_code))
    logging.info("Message for repository check: " + repo_exists.text)
    logging.info("\n")
except requests.exceptions.RequestException as e:
    logging.error("Error in checking if the repository exists: ", e)
    raise e

##################################################################
# Step 5: Register the Repository if it does not exist ###########
##################################################################

if repo_exists.status_code == 404:
    logging.info(
        "The snapshot repository does not exist. Must register a new repository."
    )
    try:
        register = requests.put(
            repositoryPath, auth=awsauth, json=payload, headers=headers
        )
        logging.info("After registering the repository...")
        logging.info("Status code for registration: " + str(register.status_code))
        logging.info("Message for registration: " + register.text)
        logging.info("\n")
    except requests.exceptions.RequestException as e:
        logging.error("Error in registering the repository: " + e)
        raise e
elif repo_exists.status_code == 200:
    logging.info("The snapshot repository already exists. No need to register it.")
else:
    logging.error("Something has gone wrong with the repository registration.")

##################################################################
# Step 6: Create the Snapshot ####################################
##################################################################

if repo_exists.status_code == 200 or register.status_code == 200:
    logging.info("The snapshot repository exists. Ready to create the snapshot.")
    try:
        snapshot = requests.put(snapshotPath, auth=awsauth)
        logging.info("After attempting to create the snapshot ...")
        logging.info("Status code for snapshot creation" + str(snapshot.status_code))
        logging.info("Message for snapshot creation: " + snapshot.text)
        logging.info("\n")
    except requests.exceptions.RequestException as e:
        logging.error("Error in creating the snapshot: " + e)
        raise e

##################################################################
# Step 7: Log the Results ########################################
##################################################################


if snapshot.status_code == 200:
    logging.info("\n------------------------")
    logging.info("Snapshot has been created successfully.")
    logging.info("------------------------\n")
else:
    logging.info("\n------------------------")
    logging.info("Snapshot process has failed.")
    logging.info("------------------------\n")
