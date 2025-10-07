import os
import json
from firebase_admin import initialize_app, remote_config, credentials

def main():
    # Get environment variables
    version = os.environ.get('VERSION', '1.0.0')
    min_version = os.environ.get('MIN_VERSION', version)
    updates = os.environ.get('UPDATES', '')

    # Convert updates to markdown list
    if updates:
        update_items = [item.strip() for item in updates.split('||') if item.strip()]
        release_notes = '\n'.join(f'- {item}' for item in update_items)
    else:
        release_notes = ''

    print(f"Updating Firebase Remote Config:")
    print(f"  Version: {version}")
    print(f"  Min Version: {min_version}")
    print(f"  Release Notes: {release_notes}")

    try:
        # Initialize Firebase Admin SDK using service account key
        service_account_key = os.environ.get('GCP_SERVICE_ACCOUNT_JSON')
        if not service_account_key:
            raise ValueError("GCP_SERVICE_ACCOUNT_JSON environment variable is required")

        # Parse the service account key JSON
        service_account = json.loads(service_account_key)

        # Initialize Firebase app
        cred = credentials.Certificate(service_account)
        app = initialize_app(cred)

        # Get current Remote Config template
        template = remote_config.get_template()

        # Update parameters
        template.parameters['latest_version'] = remote_config.Parameter(
            default_value=remote_config.ParameterValue(value=version)
        )

        template.parameters['min_version'] = remote_config.Parameter(
            default_value=remote_config.ParameterValue(value=min_version)
        )

        template.parameters['release_notes'] = remote_config.Parameter(
            default_value=remote_config.ParameterValue(value=release_notes)
        )

        # Validate and publish the template
        validated_template = remote_config.validate_template(template)
        published_template = remote_config.publish_template(validated_template)

        print(f"Successfully updated Firebase Remote Config!")
        print(f"New template version: {published_template.version}")

    except Exception as e:
        print(f"Error updating Firebase Remote Config: {str(e)}")
        exit(1)

if __name__ == "__main__":
    main()
