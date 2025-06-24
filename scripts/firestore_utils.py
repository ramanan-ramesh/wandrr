# File: firestore_utils.py

import firebase_admin
from firebase_admin import credentials, firestore

def initialize_firebase(service_account_info):
    if not firebase_admin._apps:
        cred = credentials.Certificate(service_account_info)
        firebase_admin.initialize_app(cred)
        print("✅ Firebase initialized.")
    return firestore.client()

def update_firestore_config(db, file_url, config_type):
    collection = db.collection('apiServices')
    docs = collection.where('type', '==', config_type).limit(1).get()
    doc_ref = docs[0].reference if docs else collection.document()
    if not docs:
        doc_ref.set({'type': config_type})
    doc_ref.update({
        'lastRefreshedAt': firestore.SERVER_TIMESTAMP,
        'dataUrl': file_url
    })
    print(f"✅ Firestore updated for `{config_type}`.")
