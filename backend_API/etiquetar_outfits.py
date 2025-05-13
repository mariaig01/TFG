import os
import csv
from PIL import Image
import matplotlib.pyplot as plt

# Configura aquí tus etiquetas posibles
estilos = ['casual', 'formal', 'deportivo', 'clasico', 'urbano', 'romantico', 'minimalista', 'vintage']
estaciones = ['verano', 'invierno', 'primavera', 'otoño']
ocasiones = ['trabajo', 'cita', 'diario', 'evento', 'fiesta']

IMAGES_FOLDER = 'app/datasets'
CSV_PATH = os.path.join(IMAGES_FOLDER, 'outfits.csv')

def mostrar_imagen(path):
    img = Image.open(path)
    plt.imshow(img)
    plt.axis('off')
    plt.show()

def seleccionar_etiqueta(opciones, tipo):
    print(f"\nSelecciona {tipo}:")
    for i, opcion in enumerate(opciones):
        print(f"{i + 1}. {opcion}")
    while True:
        try:
            seleccion = int(input(f"Ingrese número (1-{len(opciones)}): "))
            if 1 <= seleccion <= len(opciones):
                return opciones[seleccion - 1]
        except ValueError:
            pass
        print("❌ Opción no válida. Intenta de nuevo.")

def main():
    archivos = sorted([
        f for f in os.listdir(IMAGES_FOLDER)
        if f.lower().endswith(('.jpg', '.jpeg', '.png'))
    ])

    ya_etiquetados = set()
    if os.path.exists(CSV_PATH):
        with open(CSV_PATH, newline='', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for row in reader:
                ya_etiquetados.add(row['filename'])

    with open(CSV_PATH, 'a', newline='', encoding='utf-8') as csvfile:
        writer = csv.writer(csvfile)
        if os.stat(CSV_PATH).st_size == 0:
            writer.writerow(['filename', 'estilo', 'estacion', 'ocasion'])

        for archivo in archivos:
            if archivo in ya_etiquetados:
                continue

            print(f"\n📸 Imagen: {archivo}")
            mostrar_imagen(os.path.join(IMAGES_FOLDER, archivo))

            estilo = seleccionar_etiqueta(estilos, "estilo")
            estacion = seleccionar_etiqueta(estaciones, "estación")
            ocasion = seleccionar_etiqueta(ocasiones, "ocasión")

            writer.writerow([archivo, estilo, estacion, ocasion])
            print(f"✅ Etiquetado: {archivo} → {estilo}, {estacion}, {ocasion}")

if __name__ == '__main__':
    main()
