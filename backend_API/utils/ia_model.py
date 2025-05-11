import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing.image import load_img, img_to_array

estilos = ['casual', 'formal', 'deportivo']
estaciones = ['verano', 'invierno', 'primavera', 'otoño']
ocasiones = ['trabajo', 'cita', 'deporte', 'diario']

model = None

def load_model():
    global model
    if model is None:
        model = tf.keras.models.load_model("app/model/multitask_model.h5")

def extract_features(image_path):
    load_model()
    img = load_img(image_path, target_size=(224, 224))
    x = img_to_array(img) / 255.0
    x = np.expand_dims(x, axis=0)

    pred_estilo, pred_estacion, pred_ocasion = model.predict(x)

    estilo = estilos[np.argmax(pred_estilo)]
    estacion = estaciones[np.argmax(pred_estacion)]
    ocasion = ocasiones[np.argmax(pred_ocasion)]

    embedding = model.get_layer('embedding_layer').output

    return {
        'estilo': estilo,
        'estacion': estacion,
        'ocasion': ocasion,
        'embedding': model.get_layer('embedding_layer').output
    }
