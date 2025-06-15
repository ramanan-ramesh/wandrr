import firebase_admin
from firebase_admin import credentials, firestore
import csv
import requests
import io
import os
import json
import base64

# Initialize Firebase
def initialize_firebase(service_account_info):
    if not firebase_admin._apps:
        cred = credentials.Certificate(service_account_info)
        firebase_admin.initialize_app(cred)
        print("Firebase initialized successfully.")
    return firestore.client()

# Fetch CSV data
def fetch_csv_data(csv_url):
    print(f"Fetching CSV data from {csv_url}")
    response = requests.get(csv_url)
    if response.status_code != 200:
        print(f"Failed to download CSV: {response.status_code}")
        raise Exception(f"Failed to download CSV: {response.status_code}")
    print("CSV data fetched successfully.")
    return csv.DictReader(io.StringIO(response.text))

# Process CSV into a dictionary
def process_csv_data(reader):
    print("Processing CSV data into a dictionary.")
    airports_data = {}
    for row in reader:
        if all([
            row.get('iata_code'),
            row.get('name'),
            row.get('iso_region'),
            row.get('iso_country'),
            row.get('municipality')
        ]):
            iata = row['iata_code'].strip()
            if iata:  # Make sure iata_code is non-empty
                airports_data[iata] = {
                    'name': row['name'].strip(),
                    'city': row['municipality'].strip(),
                    'lat': float(row['latitude_deg']),
                    'lon': float(row['longitude_deg']),
                    'iata': iata
                }
    print(f"Processed {len(airports_data)} airports from the CSV.")
    return airports_data

# Write data to a JSON file
def write_json_file(data, file_path):
    print(f"Writing data to JSON file: {file_path}")
    with open(file_path, "w") as json_file:
        json.dump(data, json_file, indent=4)
    print("Data successfully written to JSON file.")

# Fetch current file content from GitHub
def fetch_github_file(github_api_url, github_headers):
    print(f"Fetching current file content from GitHub: {github_api_url}")
    response = requests.get(github_api_url, headers=github_headers)
    if response.status_code == 200:
        response_json = response.json()
        if "content" in response_json and response_json["content"]:
            print("File content fetched successfully from GitHub.")
            return base64.b64decode(response_json["content"]).decode("utf-8"), response_json["sha"]
        elif "download_url" in response_json and response_json["download_url"]:
            print("Fetching file content from download_url.")
            download_response = requests.get(response_json["download_url"])
            if download_response.status_code == 200:
                print("File content fetched successfully from download_url.")
                return download_response.text, response_json["sha"]
            else:
                print(f"Failed to fetch file content from download_url: {download_response.status_code}")
                raise Exception(f"Failed to fetch file content from download_url: {download_response.status_code}")
    elif response.status_code == 404:
        print("airports_data.json does not exist on GitHub.")
        return None, None  # File does not exist
    else:
        print(f"Failed to fetch file: {response.status_code}, {response.text}")
        raise Exception(f"Failed to fetch file: {response.status_code}, {response.text}")

# Upload or update file on GitHub
def upload_to_github(github_api_url, github_headers, file_content, message, branch, sha=None):
    print("Uploading or updating file on GitHub.")
    payload = {
        "message": message,
        "content": base64.b64encode(file_content.encode("utf-8")).decode("utf-8"),
        "branch": branch
    }
    if sha:
        payload["sha"] = sha

    response = requests.put(github_api_url, headers=github_headers, json=payload)
    if response.status_code not in [200, 201]:
        print(f"Failed to upload JSON to GitHub: {response.status_code}, {response.text}")
        raise Exception(f"Failed to upload JSON to GitHub: {response.status_code}, {response.text}")
    print("File successfully uploaded or updated on GitHub.")
    return True

# Update Firestore
def update_firestore(db, github_file_url):
    print("Updating Firestore with the new data URL.")
    api_services_ref = db.collection('apiServices')
    query = api_services_ref.where('type', '==', 'airportsData').limit(1).get()

    if query:
        config_doc_ref = query[0].reference
    else:
        config_doc_ref = api_services_ref.document()  # Create new unique ID
        config_doc_ref.set({'type': 'airportsData'})  # Initial set

    config_doc_ref.update({
        'lastRefreshedAt': firestore.SERVER_TIMESTAMP,
        'dataUrl': github_file_url
    })
    print("Firestore successfully updated.")

# Main function
def main():
    print("Starting the Airports Data Updater script.")
    # Load environment variables
    service_account_info = json.loads(os.environ["GCP_SERVICE_ACCOUNT_JSON"])
    github_token = os.environ["GITHUB_TOKEN"]

    # Initialize Firebase
    db = initialize_firebase(service_account_info)

    # Fetch and process CSV data
    CSV_URL = "https://davidmegginson.github.io/ourairports-data/airports.csv"
    reader = fetch_csv_data(CSV_URL)
    airports_data = process_csv_data(reader)

    # Write data to a JSON file
    temp_json_file_path = "airports_data.json"
    write_json_file(airports_data, temp_json_file_path)

    # GitHub configuration
    GITHUB_USERNAME = "ramanan-ramesh"
    GITHUB_REPO = "wandrr"
    GITHUB_BRANCH = "master"
    GITHUB_PATH = "docs/airports_data.json"
    GITHUB_API_URL = f"https://api.github.com/repos/{GITHUB_USERNAME}/{GITHUB_REPO}/contents/{GITHUB_PATH}"
    github_headers = {
        "Authorization": f"token {github_token}",
        "Content-Type": "application/json"
    }

    # Fetch current file from GitHub
    current_file_content, current_file_sha = fetch_github_file(GITHUB_API_URL, github_headers)

    # Compare and upload if necessary
    with open(temp_json_file_path, "r") as json_file:
        new_file_content = json_file.read()

    if current_file_content == new_file_content:
        print("No changes detected. Skipping upload.")
        did_refresh_data = False
    else:
        message = "Update airports data" if current_file_sha else "Add airports data"
        upload_to_github(GITHUB_API_URL, github_headers, new_file_content, message, GITHUB_BRANCH, current_file_sha)
        print("JSON file successfully uploaded to GitHub Pages.")
        did_refresh_data = True

    # Update Firestore if data was refreshed
    if did_refresh_data:
        github_file_url = f"https://{GITHUB_USERNAME}.github.io/{GITHUB_REPO}/{GITHUB_PATH}"
        update_firestore(db, github_file_url)
    else:
        print("No changes detected, Firestore not updated.")

    # Clean up
    os.remove(temp_json_file_path)
    print("Temporary JSON file removed. Script execution completed.")

if __name__ == "__main__":
    main()