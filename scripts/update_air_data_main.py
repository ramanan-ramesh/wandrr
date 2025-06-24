# File: main.py

import json
import os
import tempfile

from airlines_data_api import fetch_active_airlines
from airports_data_api import fetch_airports_data
from firestore_utils import initialize_firebase, update_firestore_config
from github_utils import fetch_github_file, upload_to_github


def write_json(data, path):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)


def read_file(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def process_and_upload_data(label, data, filename, github_path, config_type, db, github_headers,
                            github_branch, repo_base_url):
    print(f"\n🔄 Processing {label}...")
    write_json(data, filename)
    api_url = f"https://api.github.com/repos/{repo_base_url}/contents/{github_path}"
    local_content = read_file(filename)
    remote_content, remote_sha = fetch_github_file(api_url, github_headers)

    if local_content.strip() != (remote_content or "").strip():
        msg = f"Update {label.lower()} data"
        upload_to_github(api_url, github_headers, local_content, msg, github_branch, remote_sha)
        public_url = f"https://{repo_base_url.split('/')[0]}.github.io/{repo_base_url.split('/')[1]}/{github_path}"
        update_firestore_config(db, public_url, config_type)
    else:
        print(f"⚠️ No changes in {label} data.")


def main():
    print("\n🚦 Starting update for airports & airlines...")
    service_account_info = json.loads(os.environ["GCP_SERVICE_ACCOUNT_JSON"])
    github_token = os.environ["GITHUB_TOKEN"]

    db = initialize_firebase(service_account_info)

    github_headers = {
        "Authorization": f"token {github_token}",
        "Content-Type": "application/json"
    }
    github_ref = os.environ.get("GITHUB_REF", "")
    github_branch = github_ref.split("/")[-1] if github_ref.startswith("refs/heads/") else "master"
    repo_base_url = github_repo

    with tempfile.TemporaryDirectory() as tmp:
        airport_file = os.path.join(tmp, "airports_data.json")
        airline_file = os.path.join(tmp, "airlines_data.json")

        airport_data = fetch_airports_data(
            "https://davidmegginson.github.io/ourairports-data/airports.csv")
        process_and_upload_data(
            label="Airports",
            data=airport_data,
            filename=airport_file,
            github_path="docs/airports_data.json",
            config_type="airportsData",
            db=db,
            github_headers=github_headers,
            github_branch=github_branch,
            repo_base_url=repo_base_url
        )

        airline_data = fetch_active_airlines()
        process_and_upload_data(
            label="Airlines",
            data=airline_data,
            filename=airline_file,
            github_path="docs/airlines_data.json",
            config_type="airlinesData",
            db=db,
            github_headers=github_headers,
            github_branch=github_branch,
            repo_base_url=repo_base_url
        )

    print("\n🏁 All updates completed successfully.")


if __name__ == "__main__":
    main()
