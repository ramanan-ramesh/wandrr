const fs = require('fs');

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

const config = {
    "parameters": {
        "latest_version": {
            "defaultValue": { "value": version }
        },
        "min_version": {
            "defaultValue": { "value": minVersion }
        },
        "release_notes": {
            "defaultValue": { "value": releaseNotes }
        }
    }
};

// Write config to file
fs.writeFileSync('firebase_release_config.json', JSON.stringify(config, null, 2), 'utf8');
console.log('Firebase release config generated successfully!');
