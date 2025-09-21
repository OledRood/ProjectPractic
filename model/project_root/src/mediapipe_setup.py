import mediapipe as mp
import yaml

def setup_mediapipe(config_path):
    with open(config_path, 'r') as file:
        config = yaml.safe_load(file)

    mp_pose = mp.solutions.pose
    pose = mp_pose.Pose(
        static_image_mode=True,
        model_complexity=config['mediapipe']['model_complexity'],
        min_detection_confidence=config['mediapipe']['min_detection_confidence'],
        min_tracking_confidence=config['mediapipe']['min_tracking_confidence']
    )
    return pose
