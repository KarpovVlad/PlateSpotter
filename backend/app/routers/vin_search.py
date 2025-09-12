from fastapi import APIRouter, HTTPException
import requests
import os
from urllib.parse import urlparse
from dotenv import load_dotenv
load_dotenv()

router = APIRouter(prefix="/cars", tags=["cars"])

GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
SEARCH_ENGINE_ID = os.getenv("SEARCH_ENGINE_ID")

GROUPS = {
    "stat_vin": "stat.vin",
    "autoria": "auto.ria.com",
    "bidfax": "bidfax.info",
    "instagram": "instagram.com"
}

LANG_CODES = {"ru", "es", "uk", "ge"}

def normalize_url(url: str) -> str:
    parsed = urlparse(url)
    parts = parsed.path.split("/")
    filtered_parts = [p for p in parts if p not in LANG_CODES]
    normalized_path = "/".join([p for p in filtered_parts if p])
    return f"{parsed.scheme}://{parsed.netloc}/{normalized_path}"

@router.get("/{vin}/links")
def get_car_links(vin: str):
    try:
        url = "https://www.googleapis.com/customsearch/v1"
        params = {
            "key": GOOGLE_API_KEY,
            "cx": SEARCH_ENGINE_ID,
            "q": vin
        }
        response = requests.get(url, params=params)
        data = response.json()

        items = data.get("items", [])
        links = [item["link"] for item in items if "link" in item]

        grouped = {
            key: {"count": 0, "items": []}
            for key in GROUPS.keys()
        }
        seen = set()

        for link in links:
            parsed = urlparse(link)
            domain = parsed.netloc.replace("www.", "")

            for group, pattern in GROUPS.items():
                if pattern in domain:
                    norm = normalize_url(link)
                    if norm not in seen:
                        seen.add(norm)
                        grouped[group]["items"].append(link)
                        grouped[group]["count"] = len(grouped[group]["items"])
                    break

        return {"vin": vin, "links": grouped}

    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
