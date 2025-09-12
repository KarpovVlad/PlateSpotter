import os
import requests
from urllib.parse import urlencode
from PIL import Image
from io import BytesIO
from dotenv import load_dotenv
load_dotenv()
API_KEY = os.getenv("GOOGLE_API_KEY")
CX = os.getenv("CX")
SAVE_DIR = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/backgrounds"
os.makedirs(SAVE_DIR, exist_ok=True)

def download_images(query, num=20):
    downloaded = 0
    start = 1

    while downloaded < num:
        params = {
            "q": query,
            "cx": CX,
            "key": API_KEY,
            "searchType": "image",
            "num": min(10, num - downloaded),
            "start": start,
        }
        url = f"https://www.googleapis.com/customsearch/v1?{urlencode(params)}"
        resp = requests.get(url)
        data = resp.json()

        if "items" not in data:
            print(f"[!] Немає результата по запиту '{query}' (start={start})")
            break

        for item in data["items"]:
            try:
                img_url = item["link"]
                img_data = requests.get(img_url, timeout=5).content
                img = Image.open(BytesIO(img_data)).convert("RGB")
                filename = f"{query.replace(' ', '_')}_{downloaded+1}.jpg"
                img.save(os.path.join(SAVE_DIR, filename))
                print(f"[+] Saved {filename}")
                downloaded += 1
                if downloaded >= num:
                    break
            except Exception as e:
                print(f"[-] Помилка завантаження {item.get('link', '')}: {e}")

        start += 10

if __name__ == "__main__":
    queries = [
        "car without license plate",
        "car bumper closeup",
    ]

    for q in queries:
        download_images(q, num=30)
