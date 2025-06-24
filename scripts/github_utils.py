# File: github_utils.py

import base64
import requests


def fetch_github_file(api_url, headers):
    res = requests.get(api_url, headers=headers)
    if res.status_code == 200:
        data = res.json()
        content = base64.b64decode(data['content']).decode("utf-8") if "content" in data else None
        remote_sha = data.get("sha")
        print("api_url:", api_url)
        print("\nRemote SHA: {remote_sha}")
        if remote_sha is None:
            print("\nFile does not exist in the target branch. Creating a new file.")
        else:
            print("\nFile exists. Updating the existing file.")
        return content, data.get("sha")
    elif res.status_code == 404:
        return None, None
    else:
        raise Exception(f"GitHub error: {res.status_code} — {res.text}")


def upload_to_github(api_url, headers, content, message, branch, sha=None):
    payload = {
        "message": message,
        "content": base64.b64encode(content.encode("utf-8")).decode("utf-8"),
        "branch": branch
    }
    if sha:
        payload["sha"] = sha

    print("\npayload:", payload)

    res = requests.put(api_url, headers=headers, json=payload)
    if res.status_code not in [200, 201]:
        raise Exception(f"GitHub upload failed: {res.status_code} — {res.text}")
    print("🚀 Uploaded to GitHub successfully.")
    return True
