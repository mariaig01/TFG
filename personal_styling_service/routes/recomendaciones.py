from flask import Blueprint, request, jsonify
import os, shutil
from utils.color_analysis import analizar_color

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
        resultado = analizar_color(temp_path)
    except Exception as e:
        resultado = {"error": f"Error en el análisis: {str(e)}"}
    finally:
        os.remove(temp_path)

    return jsonify(resultado)
