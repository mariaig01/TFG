import cv2
import mediapipe as mp
import numpy as np
import os

# Landmarks de contorno facial completo (para recorte)
FACE_CONTOUR_IDX = [
    10, 338, 297, 332, 284, 251, 389, 356,
    454, 323, 361, 288, 397, 365, 379, 378,
    400, 377, 152, 148, 176, 149, 150, 136,
    172, 58, 132, 93, 234, 127, 162, 21,
    54, 103, 67, 109
]

# Landmarks clave para clasificación
# Frente (108-333), pómulos (234-454), mandíbula (234/454-152), largo (10-152)
def distancia(lms, i1, i2, w, h):
    x1, y1 = lms[i1].x * w, lms[i1].y * h
    x2, y2 = lms[i2].x * w, lms[i2].y * h
    return np.linalg.norm([x1 - x2, y1 - y2])

def dibujar_medidas(imagen, landmarks, w, h):
    def punto(i):
        return int(landmarks[i].x * w), int(landmarks[i].y * h)

    frente_pts = punto(108), punto(333)
    pomulos_pts = punto(234), punto(454)
    mandibula_pts = punto(234), punto(152), punto(454)
    largo_pts = punto(10), punto(152)

    # Clonar imagen para dibujar
    img_copy = imagen.copy()

    # Frente
    cv2.line(img_copy, frente_pts[0], frente_pts[1], (255, 0, 0), 2)
    # Pómulos
    cv2.line(img_copy, pomulos_pts[0], pomulos_pts[1], (0, 255, 0), 2)
    # Mandíbula
    cv2.line(img_copy, mandibula_pts[0], mandibula_pts[1], (0, 0, 255), 2)
    cv2.line(img_copy, mandibula_pts[1], mandibula_pts[2], (0, 0, 255), 2)
    # Largo
    cv2.line(img_copy, largo_pts[0], largo_pts[1], (255, 255, 0), 2)

    cv2.imshow("Medidas del rostro", img_copy)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

def clasificar_forma_rostro(landmarks, w, h):
    def dist(i, j):
        x1, y1 = landmarks[i].x * w, landmarks[i].y * h
        x2, y2 = landmarks[j].x * w, landmarks[j].y * h
        return np.hypot(x1 - x2, y1 - y2)

    ancho = dist(234, 454)      # pómulo ↔ pómulo
    largo = dist(10, 152)       # frente ↔ barbilla
    ratio = largo / ancho

    # Ángulo mandíbula
    v1 = np.array([landmarks[234].x - landmarks[152].x,
                   landmarks[234].y - landmarks[152].y])
    v2 = np.array([landmarks[454].x - landmarks[152].x,
                   landmarks[454].y - landmarks[152].y])
    angulo = np.degrees(np.arccos(np.dot(v1, v2) /
                                  (np.linalg.norm(v1) * np.linalg.norm(v2))))

    print(f"Ratio largo/ancho: {ratio:.2f}")
    print(f"Ángulo mandíbula: {angulo:.1f}°")

    if ratio >= 1.20 and angulo >= 102:
        return "Ovalada"
    elif angulo < 100:
        return "Cuadrada"
    else:
        return "Redonda"


def sugerir_cortes_y_peinados(forma):
    cortes = {
        "Redonda": [
            "Corte bob",
            "Corte a capas con flequillo largo",
            "Mullet"
        ],
        "Ovalada": [
            "Pixie con flequillo",
            "Corte bob italiano",
            "Wolf cut",
            "Long bob",
            "Melena con ondas"
        ],
        "Cuadrada": [
            "Bob en capas",
            "Lob texturizado",
            "Bob en ángulo",
            "Pixie despeinado"
        ]
    }

    peinados = {
        "Redonda": [
            "Ondas",
            "Alisado con puntas hacia adentro",
            "Moño con mechones fuera",
            "Messy half bun",
            "Raya al lado"
        ],
        "Ovalada": [
            "Moño sin mechones fuera",
            "Coleta sin mechones fuera",
            "Trenza de espiga en el flequillo"
        ],
        "Cuadrada": [
            "Half bun",
            "Diadema y pelo suelto",
            "Media coleta",
            "Trenza de lado",
        ]
    }

    return {
        "cortes": cortes.get(forma, []),
        "peinados": peinados.get(forma, [])
    }



def detectar_forma_rostro(image_path):
    mp_face_mesh = mp.solutions.face_mesh
    face_mesh = mp_face_mesh.FaceMesh(static_image_mode=True, max_num_faces=1)

    image = cv2.imread(image_path)
    if image is None:
        raise FileNotFoundError(f"Imagen no encontrada: {image_path}")
    h, w = image.shape[:2]
    rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)

    results = face_mesh.process(rgb)
    if not results.multi_face_landmarks:
        raise RuntimeError("No se detectó ninguna cara.")

    landmarks = results.multi_face_landmarks[0].landmark

    # Obtener puntos reales del contorno facial completo
    points = np.array([
        (int(landmarks[i].x * w), int(landmarks[i].y * h)) for i in FACE_CONTOUR_IDX
    ], dtype=np.int32)

    # Crear máscara rellenando el contorno
    mask = np.zeros((h, w), dtype=np.uint8)
    cv2.fillPoly(mask, [points], 255)

    # Aplicar máscara
    rostro = cv2.bitwise_and(image, image, mask=mask)

    # Clasificar forma con medidas anatómicas
    forma = clasificar_forma_rostro(landmarks, w, h)

    # Mostrar resultados
    print("===== DETECCIÓN DE ROSTRO =====")
    print(f"Forma detectada: {forma}")

    # Mostrar recorte
    # cv2.imshow("Máscara", mask)
    # cv2.imshow("Rostro recortado", rostro)
    # cv2.waitKey(0)
    # cv2.destroyAllWindows()

    return forma

if __name__ == "__main__":
    ruta = os.path.join(os.path.dirname(__file__), "redondo.webp")
    detectar_forma_rostro(ruta)
