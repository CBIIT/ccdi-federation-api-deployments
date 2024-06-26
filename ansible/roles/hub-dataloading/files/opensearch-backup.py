import argparse
import boto3
import requests
from requests_aws4auth import AWS4Auth

parser = argparse.ArgumentParser(description='Opensearch Backup Script')
parser.add_argument("--oshost", type=str, help="opensearch host with trailing /")
parser.add_argument("--repo", type=str, help="opensearch snapshot repository")
parser.add_argument("--s3bucket", type=str, help="s3 bucket")
parser.add_argument("--basePath", type=str, help="s3 bucket base path")
parser.add_argument("--snapshot", type=str, help="opensearch snapshot value")
args = parser.parse_args()
print(args)
oshost = args.oshost
repo = args.repo

s3bucket= args.s3bucket
snapshot= args.snapshot 
base_path= args.basePath

host = (oshost) #'https://vpc-ccdi-dev-hub-opensearch-bzgr6b4fqf4qdmgugczgdigcvm.us-east-1.es.amazonaws.com/_dashboards/' # include https:// and trailing /
region = 'us-east-1' # e.g. us-west-1
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

# Register repository
headers = {"Content-Type": "application/json"}
payload = {
  "type": "s3",
  "settings": {
    "bucket": s3bucket,
    "base_path": base_path,
    "role_arn": "arn:aws:iam::966526488680:role/power-user-ccdi-nonprod-hub-opensearch-snapshot",
    "canned_acl": "bucket-owner-full-control"
  }
}
print(payload)
r_get_repo = requests.get(oshost+'_snapshot/'+repo, auth=awsauth, json=payload, headers=headers)
if(r_get_repo.status_code!=200):
  print("repo does not exist, creating it")
  r_create_repo= requests.put(oshost+'_snapshot/'+repo, auth=awsauth, json=payload, headers=headers)
  print(r_create_repo.status_code)
  print(r_create_repo.text)




#path = '_snapshot/hub' # the OpenSearch API endpoint ## create param for this
path = '_snapshot/' # hub_s3_repository_es_710 the OpenSearch API endpoint
path = path + repo+'/' + snapshot+'/'
print(path) 
#url = f'{host}{path}'
url = host + path
payload = {
  "type": "s3",
  "settings": {
    "bucket": s3bucket,
    "base_path": base_path,
    "region": "us-east-1",
    "role_arn": "arn:aws:iam::966526488680:role/power-user-ccdi-nonprod-hub-opensearch-snapshot",
    "canned_acl": "bucket-owner-full-control"
  }
}



r = requests.put(url, auth=awsauth, json=payload, headers=headers)

print(r.status_code)
print(r.text)
if r.status_code!=200:
  raise Exception("Sorry, pipeline does not run successfully")
