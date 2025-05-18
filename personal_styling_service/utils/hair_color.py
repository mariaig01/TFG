import os
import cv2
import numpy as np
import torch
import torchvision.transforms as transforms
from sklearn.cluster import KMeans

# Importa el modelo desde utils/bisenet_model.py
from .bisenet_model import BiSeNet

# Diccionario de colores de pelo aproximados en HSV
hair_colors = {
    'Black':       ((0, 0, 0), (180, 255, 50)),
    'Dark Brown':  ((10, 20, 20), (30, 255, 90)),
    'Light Brown': ((10, 10, 60), (30, 180, 140)),
    'Blonde':      ((15, 10, 100), (40, 130, 255)),
    'Red':         ((0, 100, 60), (15, 255, 255)),
    'Gray':        ((0, 0, 100), (180, 50, 200))
}

def classify_hair_color(hsv):
    def dist(c1, c2): return np.linalg.norm(np.array(c1) - np.array(c2))
    avg_values = {name: tuple((np.array(low) + np.array(high)) // 2) for name, (low, high) in hair_colors.items()}
    return min(avg_values.items(), key=lambda item: dist(hsv, item[1]))[0]

def load_bisenet_model():
    n_classes = 19
    model = BiSeNet(n_classes=n_classes)
    base_dir = os.path.dirname(os.path.dirname(__file__))  # sube de utils/ a personal_styling_service/
    model_path = os.path.join(base_dir, 'res', '79999_iter.pth')
    model.load_state_dict(torch.load(model_path, map_location='cpu'))
    model.eval()
    return model

def segment_hair(image_path, model):
    img = cv2.imread(image_path)
    if img is None:
        raise ValueError(f"No se pudo leer la imagen en la ruta: {image_path}")
    h, w, _ = img.shape

    to_tensor = transforms.Compose([
        transforms.ToTensor(),
        transforms.Normalize(mean=[0.5]*3, std=[0.5]*3)
    ])
    resized = cv2.resize(img, (512, 512))
    tensor = to_tensor(resized).unsqueeze(0)

    with torch.no_grad():
        out = model(tensor)[0]
        parsing = out.squeeze(0).cpu().numpy().argmax(0)

    # Clase 17 representa cabello en BiSeNet
    mask = (parsing == 17).astype(np.uint8)
    mask = cv2.resize(mask, (w, h), interpolation=cv2.INTER_NEAREST)

    return img, mask

def detect_hair_color(image_path, visualize=True):
    model = load_bisenet_model()
    img, hair_mask = segment_hair(image_path, model)

    hsv_img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
    hair_pixels = hsv_img[hair_mask == 1]

    if hair_pixels.size == 0:
        raise ValueError("No se detectó cabello en la imagen.")

    # Clustering de color dominante
    kmeans = KMeans(n_clusters=2, random_state=0).fit(hair_pixels)
    dominant_hsv = kmeans.cluster_centers_[np.argmax(np.bincount(kmeans.labels_))].astype(int)
    dominant_hsv_tuple = tuple(dominant_hsv)

    color_name = classify_hair_color(dominant_hsv_tuple)

    if visualize:
        overlay = img.copy()
        overlay[hair_mask == 1] = (0, 255, 0)
        result_img = cv2.addWeighted(overlay, 0.4, img, 0.6, 0)
        cv2.putText(result_img, f"Hair: {color_name}", (30, 30),
                    cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 0), 2)
        cv2.imshow("Hair Color Detection", result_img)
        cv2.waitKey(0)
        cv2.destroyAllWindows()



    return color_name


