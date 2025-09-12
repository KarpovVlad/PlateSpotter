from ultralytics import YOLO
model = YOLO("/tasks/dataset/run/detect/train/weights/best.pt")
results = model.val(
    data="/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/dataset",
    split="test",
    imgsz=320,
    batch=16
)
print(results)
