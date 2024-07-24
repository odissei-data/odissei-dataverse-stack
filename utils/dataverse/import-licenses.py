import sys
import os
import requests


def license_upload(filename, root_url, api_token):
    headers = {"X-Dataverse-key": api_token,
               'Content-Type': 'application/json'}

    url = "%s/%s" % (root_url, "api/licenses")
    r = requests.post(url, data=open(filename, 'rb'), headers=headers)
    print(r.json())


if len(sys.argv) > 1:
    dir_path = sys.argv[1]
else:
    print("License directory required as input")
    exit()


def handle_licenses(root_url, api_token, dir_path):
    for path in os.listdir(dir_path):
        if os.path.isfile(os.path.join(dir_path, path)):
            license_upload(os.path.join(dir_path, path), root_url, api_token)


def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py <root_url> <api_token>")
        sys.exit(1)

    root_url = sys.argv[1]
    api_token = sys.argv[2]

    license_dirs = ["CBS_Licenses", "LISS_Licenses", "DANS_Licenses",
                    "Base_Licenses"]

    for directory_name in license_dirs:
        handle_licenses(root_url, api_token, "Licenses/" + directory_name)


if __name__ == "__main__":
    main()
