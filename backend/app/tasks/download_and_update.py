import requests
import zipfile
import io
import os
import json
import csv
import re
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.dialects.postgresql import insert
from sqlalchemy import text
from app.db.models import Base, Car, CarHistory

URL = "https://data.gov.ua/dataset/0ffd8b75-0628-48cc-952a-9302f9799ec0/resource/3f13166f-090b-499e-8e23-e9851c5a5f67/download/reestrtz2025.zip"
FILE_INFO_PATH = "file_info.json"
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://postgres:10203040@localhost:5432/carinfo")

engine = create_engine(DATABASE_URL)
SessionLocal = sessionmaker(bind=engine)

def load_file_info():
    if os.path.exists(FILE_INFO_PATH):
        with open(FILE_INFO_PATH, "r") as f:
            return json.load(f)
    return {}

def save_file_info(info):
    with open(FILE_INFO_PATH, "w") as f:
        json.dump(info, f)

def get_remote_file_info():
    response = requests.head(URL)
    response.raise_for_status()
    last_modified = response.headers.get("Last-Modified")
    etag = response.headers.get("ETag")
    return last_modified, etag

def download_and_extract_zip():
    print("Завантаження архіву")
    response = requests.get(URL)
    response.raise_for_status()
    with zipfile.ZipFile(io.BytesIO(response.content)) as z:
        csv_files = [info for info in z.infolist() if info.filename.lower().endswith(".csv")]
        if not csv_files:
            raise Exception("У архіві немає CSV файлів")
        newest_csv = max(csv_files, key=lambda x: x.date_time)
        print(f"Обрано файл для обробки: {newest_csv.filename}")
        with z.open(newest_csv.filename) as csvfile:
            csv_bytes = csvfile.read()
            return csv_bytes.decode("utf-8")

def convert_cyrillic_to_latin(text):
    cyr_to_lat = {
        'А': 'A',
        'В': 'B',
        'Е': 'E',
        'К': 'K',
        'М': 'M',
        'Н': 'H',
        'О': 'O',
        'Р': 'P',
        'С': 'C',
        'Т': 'T',
        'Х': 'X',
        'І': 'I',
    }
    return ''.join(cyr_to_lat.get(char, char) for char in text)

def parse_and_update_db(csv_text):
    session = SessionLocal()
    try:
        session.execute(text("TRUNCATE TABLE cars RESTART IDENTITY CASCADE;"))
        session.commit()

        reader = csv.DictReader(csv_text.splitlines(), delimiter=';')
        print("Оновлення бази даних")

        valid_plate_pattern = re.compile(r"^[A-ZА-ЯІЄЇҐ]{2}\d{4}[A-ZА-ЯІЄЇҐ]{2}$")
        skipped_empty = 0
        skipped_invalid = 0
        skipped_duplicates_csv = 0
        plates_seen = set()

        for row in reader:
            raw_plate = row.get("N_REG_NEW", "").strip().upper()
            if not raw_plate:
                skipped_empty += 1
                continue

            plate = convert_cyrillic_to_latin(raw_plate)

            if not valid_plate_pattern.match(plate):
                skipped_invalid += 1
                continue

            if plate in plates_seen:
                skipped_duplicates_csv += 1
                continue
            plates_seen.add(plate)

            car_data = {
                "plate": plate,
                "vin": row.get("VIN", "").strip(),
                "make": row.get("BRAND", "").strip(),
                "model": row.get("MODEL", "").strip(),
                "year": int(row.get("MAKE_YEAR", 0)) if row.get("MAKE_YEAR", "").isdigit() else 0,
                "engine_capacity": row.get("CAPACITY", "").strip()
            }

            history_insert = insert(CarHistory).values(**car_data)
            session.execute(history_insert)

            insert_stmt = insert(Car).values(**car_data)
            upsert_stmt = insert_stmt.on_conflict_do_update(
                index_elements=['plate'],
                set_=car_data
            )
            session.execute(upsert_stmt)

        session.commit()

        print(f"ℹПропущено {skipped_empty} порожніх номерів.")
        print(f"ℹПропущено {skipped_invalid} невалідних номерів.")
        print(f"ℹПропущено {skipped_duplicates_csv} дублікатів номерів у CSV.")
        print("База оновлена.")

    except Exception as e:
        session.rollback()
        print("Помилка при оновленні БД:", e)
        raise
    finally:
        session.close()

def main():
    old_info = load_file_info()
    try:
        last_modified_remote, etag_remote = get_remote_file_info()
    except Exception as e:
        print("Не вдалось отримати інформацію про файл:", e)
        return

    # if (old_info.get("last_modified") == last_modified_remote and
    #     old_info.get("etag") == etag_remote):
    #     print("ℹФайл не оновлювався. Оновлення бази не потрібне.")
    #     return

    try:
        csv_text = download_and_extract_zip()
        parse_and_update_db(csv_text)
        save_file_info({"last_modified": last_modified_remote, "etag": etag_remote})
    except Exception as e:
        print("Помилка під час завантаження або оновлення:", e)

if __name__ == "__main__":
    main()
