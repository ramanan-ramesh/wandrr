const { initializeApp, cert } = require('firebase-admin/app');
const { getRemoteConfig } = require('firebase-admin/remote-config');
const fs = require('fs');

async function updateFirebaseRemoteConfig() {
    try {
        // Get environment variables
        const version = process.env.VERSION || '1.0.0';
        const minVersion = process.env.MIN_VERSION || version;
        const updates = process.env.UPDATES || '';

        // Convert updates to markdown list
        let releaseNotes = '';
        if (updates) {
            const updateItems = updates.split('||')
                .map(item => item.trim())
                .filter(item => item);
            releaseNotes = updateItems.map(item => `- ${item}`).join('\n');
        }

        console.log('Updating Firebase Remote Config:');
        console.log(`  Version: ${version}`);
        console.log(`  Min Version: ${minVersion}`);
        console.log(`  Release Notes: ${releaseNotes}`);

        // Initialize Firebase Admin SDK using service account key
        const serviceAccountKey = process.env.GCP_SERVICE_ACCOUNT_JSON;
        if (!serviceAccountKey) {
            throw new Error('GCP_SERVICE_ACCOUNT_JSON environment variable is required');
        }

        // Parse the service account key JSON
        const serviceAccount = JSON.parse(serviceAccountKey);

        // Initialize Firebase app
        const app = initializeApp({
            credential: cert(serviceAccount)
        });

        // Get Remote Config instance
        const remoteConfig = getRemoteConfig(app);

        // Get current template
        const template = await remoteConfig.getTemplate();

        // Update parameters
        template.parameters['latest_version'] = {
            defaultValue: { value: version }
        };

        template.parameters['min_version'] = {
            defaultValue: { value: minVersion }
        };

        template.parameters['release_notes'] = {
            defaultValue: { value: releaseNotes }
        };

        // Validate and publish the template
        const publishedTemplate = await remoteConfig.publishTemplate(template);

        console.log('Successfully updated Firebase Remote Config!');
        console.log(`New template version: ${publishedTemplate.version}`);

    } catch (error) {
        console.error('Error updating Firebase Remote Config:', error.message);
        process.exit(1);
    }
}

updateFirebaseRemoteConfig();
