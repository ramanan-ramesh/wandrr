import os
import json

version = os.environ.get('VERSION', '1.0.0')
min_version = os.environ.get('MIN_VERSION', version)
updates = os.environ.get('UPDATES', '')

# Convert updates to markdown list
if updates:
    update_items = [item.strip() for item in updates.split('||') if item.strip()]
    release_notes = '\n'.join(f'- {item}' for item in update_items)
else:
    release_notes = ''

config = {
    "parameters": {
        "latest_version": {
            "defaultValue": {"value": version}
        },
        "min_version": {
            "defaultValue": {"value": min_version}
        },
        "release_notes": {
            "defaultValue": {"value": release_notes}
        }
    }
}

with open('firebase_release_config.json', 'w', encoding='utf-8') as f:
    json.dump(config, f, ensure_ascii=False, indent=2)

