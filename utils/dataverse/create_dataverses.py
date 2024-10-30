import json
import os
import sys

import requests

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATAVERSE_DIR = os.path.join(SCRIPT_DIR, "dataverses")
DATAVERSE_NL_SUBDIR = os.path.join(DATAVERSE_DIR, "dataversenl_subverses")


def create_dataverse(parent, json_path, dataverse_url, api_token):
    # Read dataverse data from the JSON file
    with open(json_path, "r") as json_file:
        dataverse_data = json.load(json_file)

    # Convert the dictionary to JSON format
    json_data = json.dumps(dataverse_data)

    # Set the API endpoint for creating a dataverse
    url = f"{dataverse_url}/api/dataverses/{parent}"

    # Set headers for the request, including the API token
    headers = {
        "X-Dataverse-key": api_token,
        "Content-Type": "application/json"
    }

    # Make the HTTP request to create the dataverse
    response = requests.post(url, headers=headers, data=json_data)

    # Check the response status
    if response.status_code == 201:
        print("Dataverse created successfully!")
        # Parse and print the JSON response
        dataverse_info = response.json()
        print("Dataverse ID:", dataverse_info.get("data").get("id"))
    else:
        print(f"Error creating dataverse. Status code: {response.status_code}")
        print("Response content:", response.text)


def update_dataverse(dataverse_id, json_path, dataverse_url, api_token):
    # Read the updated dataverse data from the JSON file

    full_json_path = os.path.join(DATAVERSE_DIR, json_path)

    if not os.path.exists(full_json_path):
        print(f"Error: JSON file not found at {full_json_path}")
        return

    with open(full_json_path, "r") as json_file:
        updated_data = json.load(json_file)

    # Convert the dictionary to JSON format
    json_data = json.dumps(updated_data)

    # Set the API endpoint for updating the dataverse
    url = f"{dataverse_url}/api/dataverses/{dataverse_id}"

    # Set headers for the request, including the API token
    headers = {
        "X-Dataverse-key": api_token,
        "Content-Type": "application/json"
    }

    # Make the HTTP request to update the dataverse
    response = requests.put(url, headers=headers, data=json_data)

    # Check the response status
    if response.status_code == 200:
        print("Dataverse updated successfully.")
    else:
        print(f"Failed to update dataverse: {response.status_code} - {response.text}")


def create_odissei_dataverses(dataverse_url, api_token):
    parent_root = "root"
    parent_dv_nl = "DV_NL"
    json_paths = ["cbs.json", "cid.json", "dans.json", "dataversenl.json",
                  "hsn.json", "liss.json"]

    for json_path in json_paths:
        full_json_path = os.path.join(DATAVERSE_DIR, json_path)
        if os.path.exists(full_json_path):
            create_dataverse(parent_root, full_json_path, dataverse_url,
                             api_token)
        else:
            print(f"Error: JSON file not found at {full_json_path}")

    # List of JSON paths for the second set of dataverses with parent DV_NL
    json_paths_dv_nl = [
        "avans.json", "delft.json", "fontys.json", "groningen.json",
        "hanze.json", "hr.json", "leiden.json", "maastricht.json",
        "tilburg.json", "trimbos.json", "twente.json", "umcu.json",
        "utrecht.json", "vu.json"
    ]

    for json_path in json_paths_dv_nl:
        full_json_path = os.path.join(DATAVERSE_NL_SUBDIR, json_path)
        if os.path.exists(full_json_path):
            create_dataverse(parent_dv_nl, full_json_path, dataverse_url,
                             api_token)
        else:
            print(f"Error: JSON file not found at {full_json_path}")


def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py root_url api_token")
        sys.exit(1)

    root_url = sys.argv[1]
    api_token = sys.argv[2]

    create_odissei_dataverses(root_url, api_token)
    update_dataverse("root", "odissei-portal.json", root_url, api_token)


if __name__ == "__main__":
    main()
