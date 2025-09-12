import os
import shutil
import random
import json
from tqdm import tqdm

SYN_IMAGES_DIR = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/synthetic_dataset"
SYN_LABELS_JSON = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/synthetic_dataset/labels.json"
REAL_IMAGES_DIR = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/plates_dataset"

OUT_DIR = "dataset"
for split in ["train", "val", "test"]:
    os.makedirs(os.path.join(OUT_DIR, "images", split), exist_ok=True)
    os.makedirs(os.path.join(OUT_DIR, "labels", split), exist_ok=True)

with open(SYN_LABELS_JSON, "r") as f:
    syn_ann = json.load(f)

syn_files = list(syn_ann.keys())
random.shuffle(syn_files)
train_split = int(len(syn_files) * 0.8)
train_files = syn_files[:train_split]
val_files = syn_files[train_split:]
real_files = [f for f in os.listdir(REAL_IMAGES_DIR) if f.lower().endswith((".jpg", ".png"))]

def process_file(fname, split, images_dir, target_dir):
    base_name = os.path.splitext(fname)[0]
    img_src = os.path.join(images_dir, fname)
    txt_src = os.path.join(images_dir, base_name + ".txt")
    img_dst = os.path.join(target_dir, "images", split, fname)
    txt_dst = os.path.join(target_dir, "labels", split, base_name + ".txt")
    os.makedirs(os.path.dirname(img_dst), exist_ok=True)
    os.makedirs(os.path.dirname(txt_dst), exist_ok=True)
    if os.path.exists(img_src):
        shutil.move(img_src, img_dst)
    if os.path.exists(txt_src):
        shutil.move(txt_src, txt_dst)
    else:
        print(f"Warning: no label file for {fname}")

for f in tqdm(train_files, desc="Train split"):
    process_file(f, "train", SYN_IMAGES_DIR, OUT_DIR)

for f in tqdm(val_files, desc="Val split"):
    process_file(f, "val", SYN_IMAGES_DIR, OUT_DIR)

for f in tqdm(real_files, desc="Test split"):
    img_path = os.path.join(REAL_IMAGES_DIR, f)
    dst_img = os.path.join(OUT_DIR, "images", "test", f)
    if os.path.exists(img_path):
        shutil.move(img_path, dst_img)

yaml_content = f"""
train: ./images/train
val: ./images/val
test: ./images/test

nc: 1
names: ["license_plate"]
"""

with open(os.path.join(OUT_DIR, "dataset.yaml"), "w") as f:
    f.write(yaml_content)
