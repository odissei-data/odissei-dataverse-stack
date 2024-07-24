import sys
import os
import requests
from config import API_TOKEN, ROOT


def license_upload(filename):

    headers = {"X-Dataverse-key": API_TOKEN, 'Content-Type': 'application/json'}

    url = "%s/%s" % (ROOT, "api/licenses")
    r = requests.post(url, data=open(filename, 'rb'), headers=headers)
    print(r.json())


if len(sys.argv) > 1:
    dir_path = sys.argv[1]
else:
    print("License directory required as input")
    exit()

for path in os.listdir(dir_path):
    print(os.path.join(dir_path, path))
    if os.path.isfile(os.path.join(dir_path, path)):
        license_upload(os.path.join(dir_path, path))
