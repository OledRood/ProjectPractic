from ultralytics import YOLO
import yaml

def load_model(config_path):
    with open(config_path, 'r') as file:
        config = yaml.safe_load(file)

    model_path = config['model']['weights_path']
    model = YOLO(model_path)
    return model
