import argparse
import boto3
import requests
from requests_aws4auth import AWS4Auth
import time

parser = argparse.ArgumentParser(description='Opensearch Backup Script')
parser.add_argument("--oshost", type=str, help="opensearch host with trailing /")
parser.add_argument("--repo", type=str, help="opensearch snapshot repository")
parser.add_argument("--s3bucket", type=str, help="s3 bucket")
parser.add_argument("--snapshot", type=str, help="opensearch snapshot value")
parser.add_argument("--indices", type=str, help="indices")
parser.add_argument("--rolearn", type=str, help="role arn - typically power user role")
parser.add_argument("--basepath", type=str, help="basepath")
args = parser.parse_args()
oshost = args.oshost
repo = args.repo
s3bucket= args.s3bucket
snapshot= args.snapshot 
indices = args.indices
rolearn = args.rolearn 
basepath = args.basepath
# test
host = oshost #'https://vpc-ccdi-dev-hub-opensearch-bzgr6b4fqf4qdmgugczgdigcvm.us-east-1.es.amazonaws.com/_dashboards/' # include https:// and trailing /
region = 'us-east-1' # e.g. us-west-1
service = 'es'
credentials = boto3.Session().get_credentials()
awsauth = AWS4Auth(credentials.access_key, credentials.secret_key, region, service, session_token=credentials.token)

print(awsauth)
path = '_snapshot/'+repo # the OpenSearch API endpoint
url = host + path
payload_s3 = {
  "type": "s3",
  "settings": {
    "bucket": s3bucket,
    "base_path": basepath,
    "region": "us-east-1",
    "role_arn": "arn:aws:iam::966526488680:role/power-user-ccdi-nonprod-hub-opensearch-snapshot"
  }
}
print(payload_s3)
headers = {"Content-Type": "application/json"}
print("starting register repo")
r = requests.put(url, auth=awsauth, json=payload_s3, headers=headers)

print(r.status_code)
print(r.text)
time.sleep(100) 

path = '_snapshot/'+repo+'/'+snapshot+'/_restore'

headers = {"Content-Type": "application/json"}
print("starting deleting the indices")
indice_arr = indices.split(",")
for i in indice_arr:
  check = requests.get(oshost+i, auth=awsauth, headers=headers)
  if check.status_code==200:
    r = requests.delete(oshost+i, auth=awsauth, headers=headers)
    print(r.text)

print("finished deleting the indices, waiting 2 mins for the deletion to complete")
time.sleep(120) 
print("started restore the indices")
payload_restore = {
  "indices": indices,
  "include_global_state": False
}
print(payload_restore)
r = requests.post(oshost+path, auth=awsauth, json=payload_restore, headers=headers)
#
print(r.text)
if r.status_code!=200:
  raise Exception("Sorry, pipeline does not run successfully")
