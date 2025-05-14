from werkzeug.datastructures import FileStorage

def analizar_foto(imagen: FileStorage) -> dict:
    # Leer contenido si lo necesitas
    contenido = imagen.read()

    # Aquí irá el modelo real. Simulación por ahora:
    return {
        'colores': ['Verde oliva', 'Beige', 'Rosa pastel'],
        'peinados': ['Trenza lateral', 'Moño bajo'],
        'maquillaje': 'Tonos cálidos con labial coral'
    }
