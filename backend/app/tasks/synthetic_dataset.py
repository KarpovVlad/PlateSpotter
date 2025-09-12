import os
import random
import json
import cv2
import numpy as np
from PIL import Image, ImageDraw, ImageFont

OUTPUT_DIR = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/synthetic_dataset"
BACKGROUND_DIR = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/backgrounds"
os.makedirs(OUTPUT_DIR, exist_ok=True)
FONT_PATH = "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/licenseplate.ttf"
TEMPLATES = [
    "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/IMG_9967.png",
    "/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/IMG_9966.png"
]

template_index = 0
FORMATS = ["AA0000BB"]
LETTERS = list("ABCEHIKMOPTXY")
DIGITS = list("0123456789")

PLATE_COLORS = {
    "white": (255, 255, 255),
    "yellow": (255, 255, 100),
    "green": (180, 255, 180),
}

def generate_plate_text(fmt: str) -> str:
    plate = ""
    for ch in fmt:
        if ch == "A":
            plate += random.choice(LETTERS)
        elif ch == "0":
            plate += random.choice(DIGITS)
        else:
            plate += ch
    return plate

def generate_plate_image(plate_text: str, template_path: str):
    template = Image.open(template_path).convert("RGBA")
    img_w, img_h = template.size
    img = template.copy()
    draw = ImageDraw.Draw(img)

    try:
        font_size = int(img_h * 0.7)
        font = ImageFont.truetype(FONT_PATH, font_size)
    except:
        font = ImageFont.load_default()

    bbox = draw.textbbox((0, 0), plate_text, font=font)
    text_w, text_h = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x_offset = (img_w - text_w) // 2
    y_offset = (img_h - text_h) // 2
    draw.text((x_offset, y_offset), plate_text, font=font, fill="black")

    return cv2.cvtColor(np.array(img), cv2.COLOR_RGBA2BGR)

def warp_soft(img, max_angle=3, max_shear=0.02):
    h, w = img.shape[:2]
    plate = Image.fromarray(img)

    angle = random.uniform(-max_angle, max_angle)
    plate = plate.rotate(angle, expand=True, resample=Image.BICUBIC)

    dx = random.uniform(-max_shear, max_shear) * plate.size[0]
    coeffs = (1, dx / plate.size[1], 0,
              0, 1, 0)
    plate = plate.transform(plate.size, Image.AFFINE, coeffs, resample=Image.BICUBIC)

    arr = np.array(plate)
    x_min, y_min, x_max, y_max = 0, 0, arr.shape[1], arr.shape[0]
    return arr, (x_min, y_min, x_max, y_max)

def overlay_on_car(plate_img, bbox, bg_path):
    bg = cv2.imread(bg_path)
    if bg is None:
        return None, None
    h_bg, w_bg = bg.shape[:2]

    scale = random.uniform(0.25, 0.5)
    new_w, new_h = int(w_bg * scale), int(h_bg * scale * 0.15)
    plate_img = cv2.resize(plate_img, (new_w, new_h))

    x_min = int(w_bg * 0.2)
    x_max = int(w_bg * 0.8 - new_w)

    if x_max <= x_min:
        x_offset = max(0, (w_bg - new_w) // 2)
    else:
        x_offset = random.randint(x_min, x_max)

    y_min = int(h_bg * 0.65)
    y_max = int(h_bg * 0.9 - new_h)

    if y_max <= y_min:
        y_offset = max(0, h_bg - new_h - 5)
    else:
        y_offset = random.randint(y_min, y_max)

    roi = bg[y_offset:y_offset+new_h, x_offset:x_offset+new_w]
    mask = cv2.cvtColor(plate_img, cv2.COLOR_BGR2GRAY)
    _, mask = cv2.threshold(mask, 1, 255, cv2.THRESH_BINARY)

    plate_region = cv2.bitwise_and(plate_img, plate_img, mask=mask)
    inv_mask = cv2.bitwise_not(mask)
    bg_roi = cv2.bitwise_and(roi, roi, mask=inv_mask)
    combined = cv2.add(bg_roi, plate_region)
    bg[y_offset:y_offset+new_h, x_offset:x_offset+new_w] = combined

    x_min, y_min, x_max, y_max = bbox
    x_min, x_max = x_min / new_w * new_w + x_offset, x_max / new_w * new_w + x_offset
    y_min, y_max = y_min / new_h * new_h + y_offset, y_max / new_h * new_h + y_offset

    return bg, (x_min, y_min, x_max, y_max)

def bbox_to_yolo(bbox, img_w, img_h):
    x_min, y_min, x_max, y_max = bbox
    x_center = (x_min + x_max) / 2 / img_w
    y_center = (y_min + y_max) / 2 / img_h
    w = (x_max - x_min) / img_w
    h = (y_max - y_min) / img_h
    return f"0 {x_center:.6f} {y_center:.6f} {w:.6f} {h:.6f}"

def main(n=1):
    global template_index
    annotations = {}
    bg_files = [os.path.join(BACKGROUND_DIR, f) for f in os.listdir(BACKGROUND_DIR) if f.lower().endswith((".jpg",".png"))]

    for i in range(n):
        fmt = random.choice(FORMATS)
        plate_text = generate_plate_text(fmt)
        template_path = TEMPLATES[template_index % len(TEMPLATES)]
        template_index += 1
        plate_img = generate_plate_image(plate_text, template_path)
        warped, bbox = warp_soft(plate_img)
        bg_path = random.choice(bg_files)
        final_img, bbox = overlay_on_car(warped, bbox, bg_path)
        if final_img is None:
            continue

        filename = f"plate_{i}.jpg"
        filepath = os.path.join(OUTPUT_DIR, filename)
        cv2.imwrite(filepath, final_img)
        yolo_label = bbox_to_yolo(bbox, final_img.shape[1], final_img.shape[0])
        with open(os.path.join(OUTPUT_DIR, f"plate_{i}.txt"), "w") as f:
            f.write(yolo_label)

        annotations[filename] = plate_text

    with open(os.path.join(OUTPUT_DIR, "labels.json"), "w") as f:
        json.dump(annotations, f, indent=2, ensure_ascii=False)

if __name__ == "__main__":
    main(1)
