import json
import os
import sys

import requests

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATAVERSE_DIR = os.path.join(SCRIPT_DIR, "dataverses")
DATAVERSE_NL_SUBDIR = os.path.join(DATAVERSE_DIR, "dataversenl_subverses")
ROOT_DIR = os.path.join(DATAVERSE_DIR, "root")
ROOT_ID = "root"


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

# curl -H "X-Dataverse-key:$API_TOKEN" -X POST "$SERVER_URL/api/dataverses/$ID/actions/:publish"
def publish_dataverse(alias, dataverse_url, api_token):
    # Set the API endpoint for publishing a dataverse
    url = f"{dataverse_url}/api/dataverses/{alias}/actions/:publish"

    # Set headers for the request, including the API token
    headers = {
        "X-Dataverse-key": api_token,
        "Content-Type": "application/json"
    }

    # Make the HTTP request to publish the dataverse
    response = requests.post(url, headers=headers)

    # Check the response status
    if response.status_code == 200:
        print(f"Dataverse {alias} published successfully!")
    else:
        print(f"Error publishing dataverse: {alias}. Status code: {response.status_code}")
        print("Response content:", response.text)

# curl -H "X-Dataverse-key:$API_TOKEN" -X DELETE "$SERVER_URL/api/dataverses/$ID/featured"
def set_featured_dataverses(dataverse_id, aliases, dataverse_url, api_token):
    print("Setting featured dataverses...")
    # Set the API endpoint for setting featured dataverses
    url = f"{dataverse_url}/api/dataverses/{dataverse_id}/featured"

    # Set headers for the request, including the API token
    headers = {
        "X-Dataverse-key": api_token,
        "Content-Type": "application/json"
    }

    # aliases is a list strings; the aliases are the dataverses to be featured
    data = aliases

    # Convert the dictionary to JSON format
    json_data = json.dumps(data)

    # Make the HTTP request to set featured dataverses
    response = requests.post(url, headers=headers, data=json_data)

    # Check the response status
    if response.status_code == 200:
        print("Featured dataverses updated successfully.")
    else:
        print(
            f"Failed to update featured dataverses:"
            f" {response.status_code} - {response.text}")
    
    print("Featured dataverses update done.")

def set_search_facets(dataverse_id, facets_file_path, dataverse_url,
                      api_token):
    print("Setting search facets...")
    # Set the API endpoint for setting search facets
    url = f"{dataverse_url}/api/dataverses/{dataverse_id}/facets"

    # Set headers for the request, including the API token
    headers = {
        "X-Dataverse-key": api_token,
    }

    full_json_path = os.path.join(ROOT_DIR, facets_file_path)
    if not os.path.exists(full_json_path):
        print(f"Error: JSON file not found at {full_json_path}")
        return

    with open(full_json_path, 'rb') as facets_file:
        response = requests.post(url, headers=headers, data=facets_file)

    # Check the response status
    if response.status_code == 200:
        print("Search facets updated successfully.")
    else:
        print(
            f"Failed to update search facets:"
            f" {response.status_code} - {response.text}")
    
    print("Search facets update done.")

def define_metadata_blocks(dataverse_id, metadata_file_path, dataverse_url,
                           api_token):
    print("Defining metadata blocks...")
    # Set the API endpoint for defining metadata blocks
    url = f"{dataverse_url}/api/dataverses/{dataverse_id}/metadatablocks"

    # Set headers for the request, including the API token
    headers = {
        "X-Dataverse-key": api_token,
        "Content-type": "application/json"
    }

    full_json_path = os.path.join(ROOT_DIR, metadata_file_path)
    if not os.path.exists(full_json_path):
        print(f"Error: JSON file not found at {full_json_path}")
        return

    with open(full_json_path, 'r') as metadata_file:
        metadata_json = metadata_file.read()
        response = requests.post(url, headers=headers, data=metadata_json)

    # Check the response status
    if response.status_code == 200:
        print("Metadata blocks defined successfully.")
    else:
        print(
            f"Failed to define metadata blocks:"
            f" {response.status_code} - {response.text}")
    
    print("Metadata blocks definition done.")

def create_odissei_dataverses(dataverse_url, api_token):
    parent_root = "root"
    parent_dv_nl = "DV_NL"
    json_paths = ["cbs.json", "cid.json", "dans.json", "dataversenl.json",
                  "hsn.json", "liss.json"]

    print("Creating odissei dataverses...")
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
    
    print("Dataverses for odissei creation done.")


def main():
    if len(sys.argv) != 3:
        print("Usage: python script.py root_url api_token")
        sys.exit(1)
    print("Creating dataverses...")
    root_url = sys.argv[1]
    api_token = sys.argv[2]

    print(f"Using root_url: {root_url}")
    print(f"Using api_token: {api_token}")
    
    create_odissei_dataverses(root_url, api_token)
    define_metadata_blocks(ROOT_ID, "metadatablocks.json", root_url, api_token)
    set_search_facets(ROOT_ID, "facets.json", root_url, api_token)
    print("Dataverses creation done.")

    # publsh dataverses
    print("Publishing dataverses...")
    # should have the aliases, and publish in correct order
    # aliases are now in those json files
    # note that the order matters for setting featured dataverses later on
    top_level_aliases = ["cbs", "liss", "dans", "DV_NL", "cid", "HSN_NL"]
    # publish the top level dataverses first
    for alias in top_level_aliases:
        publish_dataverse(alias, root_url, api_token)
    # publish the dataverses under DV_NL
    sub_level_aliases = [
        "AvansHogeschool", "delft", "fontys", "groningen", "hanze", "hr",
        "leidenuniversity", "maastricht", "tiu", "trimbos", "twente",
        "umcu", "UU", "vuamsterdam"
    ]
    for alias in sub_level_aliases:
        publish_dataverse(alias, root_url, api_token)
    print("Dataverses publishing done.")

    print("Setting featured dataverses...")
    # only the top level dataverses are featured
    set_featured_dataverses(ROOT_ID, top_level_aliases, root_url, api_token)

    # Note that we don't set the logo's for the dataverses!

    print("All done.")
    
if __name__ == "__main__":
    main()
