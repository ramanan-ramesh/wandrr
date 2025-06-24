# File: airlines_data_api.py

import requests
from bs4 import BeautifulSoup
import re

def fetch_active_airlines():
    print("\n✈️ Fetching airlines from Wikipedia...")
    url = "https://en.wikipedia.org/wiki/List_of_airline_codes"
    response = requests.get(url, headers={"User-Agent": "Mozilla/5.0"})
    response.raise_for_status()
    soup = BeautifulSoup(response.content, "lxml")

    table = soup.find("table", class_="wikitable")
    headers_row = table.find("tr")
    header_titles = [th.get_text(strip=True).lower() for th in headers_row.find_all("th")]

    iata_index = header_titles.index("iata")
    airline_index = header_titles.index("airline")

    airlines = []
    for row in table.find_all("tr")[1:]:
        cols = row.find_all("td")
        if len(cols) <= max(iata_index, airline_index):
            continue

        iata = cols[iata_index].get_text(strip=True)
        airline_cell = cols[airline_index]

        if airline_cell.find("i"):
            continue  # defunct

        if not (len(iata) == 2 and iata.isalnum()):
            continue

        raw_name = airline_cell.get_text(strip=True)
        name = re.sub(r"\\[.*?\\]|\\(.*?\\)", "", raw_name).strip()
        if name:
            airlines.append({"name": name, "iata": iata})

    print(f"✅ Processed {len(airlines)} active airlines.")
    return airlines
