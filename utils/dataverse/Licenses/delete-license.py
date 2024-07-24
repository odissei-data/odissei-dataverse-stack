"""
curl https://portal.staging.odissei.nl/api/licenses
to retrieve list of licenses and id's
"""

import sys
import requests
from config import *


def delete_license(persistent_identifier):
    headers = {"X-Dataverse-key": API_TOKEN}

    url = "%s/api/licenses/%s" % (ROOT, persistent_identifier)
    r = requests.delete(url, headers=headers)
    print(r.json())


if len(sys.argv) > 1:
    pid = sys.argv[1]
else:
    print("License directory required as input")
    exit()

delete_license(pid)
