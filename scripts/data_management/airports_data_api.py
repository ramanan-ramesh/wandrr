# File: airports_data_api.py

import csv
import io
import requests

def fetch_airports_data(csv_url):
    print("\n🛬 Fetching airports CSV...")
    res = requests.get(csv_url)
    res.raise_for_status()
    reader = csv.DictReader(io.StringIO(res.text))
    airports = []
    for row in reader:
        if all([
            row.get('iata_code'),
            row.get('name'),
            row.get('iso_region'),
            row.get('iso_country'),
            row.get('municipality')
        ]):
            iata = row['iata_code'].strip()
            if iata:
                airports.append({
                    'name': row['name'].strip(),
                    'city': row['municipality'].strip(),
                    'lat': float(row['latitude_deg']),
                    'lon': float(row['longitude_deg']),
                    'iata': iata
                })
    print(f"✅ Processed {len(airports)} airports.")
    return airports
