import cv2

# Cargar modelos pre-entrenados de detección de rostro y ojos
face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
eye_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_eye.xml')

# Ruta de la imagen
image_path = 'angelinajolie.jpg'  # Cambia esto por tu archivo real

# Cargar imagen
image = cv2.imread(image_path)
if image is None:
    print("No se pudo cargar la imagen.")
    exit()

# Convertir a escala de grises
gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)

# Detectar rostros
faces = face_cascade.detectMultiScale(gray, 1.3, 5)

# Para cada rostro detectado
for (x, y, w, h) in faces:
    cv2.rectangle(image, (x, y), (x + w, y + h), (255, 0, 0), 2)

    roi_gray = gray[y:y + h, x:x + w]
    roi_color = image[y:y + h, x:x + w]

    eyes = eye_cascade.detectMultiScale(roi_gray)

    for (ex, ey, ew, eh) in eyes:
        cv2.rectangle(roi_color, (ex, ey), (ex + ew, ey + eh), (0, 255, 0), 2)

        eye_roi = roi_gray[ey:ey + eh, ex:ex + ew]
        avg_pixel_intensity = cv2.mean(eye_roi)[0]

        if avg_pixel_intensity < 90:
            eye_color = "Dark"
        elif avg_pixel_intensity < 120:
            eye_color = "Brown"
        elif avg_pixel_intensity < 150:
            eye_color = "Hazel"
        elif avg_pixel_intensity < 180:
            eye_color = "Green"
        else:
            eye_color = "Blue"

        cv2.putText(roi_color, eye_color, (ex, ey - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

# Mostrar resultado
cv2.imshow('Eye Color Detection - Image', image)
cv2.waitKey(0)
cv2.destroyAllWindows()
