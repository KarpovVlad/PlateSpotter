from ultralytics import YOLO
model = YOLO("/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/dataset/run/detect/train/weights/best.pt")

results = model.predict(
    source="/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/dataset/images/test",
    imgsz=320,
    conf=0.3,
    save=True,
    project="/Users/vladkarpov/PycharmProjects/PlateSpotter/backend/app/tasks/dataset/run/detect",
    name="test_predictions"
)

print("Результати збережені у run/detect/test_predictions")
