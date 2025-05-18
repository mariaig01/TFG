import cv2
import mediapipe as mp
import numpy as np

# 1) Definimos rangos en grados y % para cada color:
class_name = ("Blue", "Blue Gray", "Brown", "Brown Gray", "Brown Black", "Green", "Green Gray", "Other")
EyeColorDegPct = {
    "Blue":        ((166, 21, 50), (240, 100, 85)),
    "Blue Gray":   ((166, 2,  25), (300, 20,  75)),
    "Brown":       ((2,   20, 20), (40,  100, 60)),
    "Brown Gray":  ((20,  3,  30), (65,  60,  60)),
    "Brown Black": ((0,   10, 5 ), (40,  40,  25)),
    "Green":       ((60,  21, 50), (165, 100, 85)),
    "Green Gray":  ((60,  2,  25), (165, 20,  65))
}

# 2) Convertimos esos rangos a la escala de OpenCV:
EyeColorHSV = {}
for name, (low, high) in EyeColorDegPct.items():
    lh_deg, ls_pct, lv_pct = low
    hh_deg, hs_pct, hv_pct = high
    EyeColorHSV[name] = (
        (int(lh_deg/2), int(ls_pct*255/100), int(lv_pct*255/100)),
        (int(hh_deg/2), int(hs_pct*255/100), int(hv_pct*255/100))
    )

def classify_iris(hsv_iris_pixels):
    """Cuenta votos por cada color y devuelve un diccionario de porcentajes."""
    votes = {c: 0 for c in class_name}
    total = hsv_iris_pixels.shape[0]
    for pix in hsv_iris_pixels:
        h, s, v = map(int, pix)
        for name, (low, high) in EyeColorHSV.items():
            if low[0] <= h <= high[0] and low[1] <= s <= high[1] and low[2] <= v <= high[2]:
                votes[name] += 1
                break
        else:
            votes["Other"] += 1
    # Convertimos a porcentaje
    perc = {c: round(votes[c] / total * 100, 2) for c in votes}
    return perc

def detect_eye_color(image_path,  visualize=True):
    img = cv2.imread(image_path)
    if img is None:
        print("No se pudo leer la imagen.")
        return

    h, w = img.shape[:2]
    mp_face = mp.solutions.face_mesh
    with mp_face.FaceMesh(static_image_mode=True,
                          max_num_faces=1,
                          refine_landmarks=True) as fm:
        rgb = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        res = fm.process(rgb)
        if not res.multi_face_landmarks:
            print("No se detectó ninguna cara.")
            return
        lm = res.multi_face_landmarks[0].landmark

    # LEFT_IRIS  = [476, 473, 374]
    # RIGHT_IRIS = [471, 468, 145]
    LEFT_IRIS = [471, 159, 469,145]
    RIGHT_IRIS = [476, 374, 474,386]
    hsv_img = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

    percs = {}

    # 1) Clasificamos cada ojo y imprimimos % de todos los colores
    for side, idx_list in zip(("Left", "Right"), (LEFT_IRIS, RIGHT_IRIS)):
        pts = np.array([[int(lm[i].x * w), int(lm[i].y * h)] for i in idx_list])
        mask = np.zeros((h, w), dtype=np.uint8)
        cv2.fillConvexPoly(mask, pts, 255)

        iris_pixels = hsv_img[mask == 255]
        if iris_pixels.size == 0:
            print(f"{side} Eye: No se obtuvieron píxeles de iris.")
            continue

        perc = classify_iris(iris_pixels)
        percs[side] = perc

        # **Imprimimos todos los porcentajes**
        print(f"\n{side} Eye Color Percentages:")
        for color in class_name:
            print(f"  {color}: {perc[color]} %")

        # Dibujamos el triángulo en la imagen
        centroid = pts.mean(axis=0).astype(int)
        cv2.polylines(img, [pts], isClosed=True, color=(0,255,0), thickness=1)
        cv2.putText(img, f"{side}: ...",
                    (centroid[0] - 20, centroid[1] - 10),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255,255,0), 1)

    # 2) Calculamos el color dominante global excluyendo "Other"
    best_color, best_pct = None, -1
    for color in class_name[:-1]:
        max_pct = max(percs.get("Left", {}).get(color, 0),
                      percs.get("Right", {}).get(color, 0))
        if max_pct > best_pct:
            best_pct = max_pct
            best_color = color

    label = f"Dominant: {best_color} ({best_pct:.1f}%)"
    cv2.putText(img, label, (10, 30),
                cv2.FONT_HERSHEY_SIMPLEX, 1.0, (0, 255, 255), 2)
    print(f"\nOverall dominant eye color: {best_color} ({best_pct} %)\n")

    if visualize:
        cv2.imshow("Eye Color", img)
        cv2.waitKey(0)
        cv2.destroyAllWindows()

    return best_color

