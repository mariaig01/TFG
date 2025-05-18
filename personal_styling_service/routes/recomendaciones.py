from flask import Blueprint, request, jsonify
import os, shutil
from utils.color_analysis import analizar_imagen_completa
from utils.face_shape_detector import detectar_forma_rostro, sugerir_cortes_y_peinados

bp = Blueprint('recomendaciones', __name__, url_prefix='/recomendaciones')

@bp.route('/colorimetria', methods=['POST'])
def colorimetria():
    imagen = request.files.get("imagen")
    if not imagen:
        return jsonify({"error": "No se recibió ninguna imagen"}), 400

    os.makedirs("temp", exist_ok=True)
    temp_path = f"temp/{imagen.filename}"
    imagen.save(temp_path)

    try:
        resultado = analizar_imagen_completa(temp_path)
    except Exception as e:
        resultado = {"error": f"Error en el análisis: {str(e)}"}
    finally:
        os.remove(temp_path)

    return jsonify(resultado)

@bp.route('/forma-cara', methods=['POST'])
def forma_cara():
    imagen = request.files.get("imagen")
    if not imagen:
        return jsonify({"error": "No se recibió ninguna imagen"}), 400

    os.makedirs("temp", exist_ok=True)
    temp_path = f"temp/{imagen.filename}"
    imagen.save(temp_path)

    try:
        forma = detectar_forma_rostro(temp_path)
        sugerencias = sugerir_cortes_y_peinados(forma)
        resultado = {
            "forma": forma,
            "sugerencias": sugerencias
        }
    except Exception as e:
        resultado = {"error": f"Error en la detección: {str(e)}"}
    finally:
        os.remove(temp_path)

    return jsonify(resultado)
