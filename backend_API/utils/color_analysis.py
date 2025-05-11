from sklearn.cluster import KMeans
from PIL import Image
import numpy as np

def extract_colors(image_path, k=3):
    img = Image.open(image_path).resize((100, 100))
    data = np.array(img).reshape((-1, 3))
    kmeans = KMeans(n_clusters=k).fit(data)
    colores = kmeans.cluster_centers_.astype(int)
    return [f'rgb({r},{g},{b})' for r, g, b in colores]
