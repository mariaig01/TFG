import os
from flask import Blueprint, request, jsonify, send_file
from flask_jwt_extended import jwt_required, get_jwt_identity
from io import BytesIO
from werkzeug.utils import secure_filename

from backend_API.extensions import db
from backend_API.models import Post

posts_bp = Blueprint('posts', __name__, url_prefix='/posts')

# Ruta: Crear publicación desde Flutter (JWT)
@posts_bp.route('/api/create-mobile', methods=['POST'])
@jwt_required()
def crear_post_mobile():
    """Crear publicación desde Flutter usando JWT"""
    print("→ JSON recibido:", request.get_json(force=True))
    print("→ Content-Type:", request.content_type)
    print("→ Headers:", dict(request.headers))

    usuario_id = int(get_jwt_identity())
    data = request.get_json()

    contenido = data.get('contenido', '').strip()
    visibilidad = data.get('visibilidad', 'publico')
    imagen_url = data.get('imagen_url')  # opcional

    # Validaciones
    if not contenido:
        return jsonify({'error': 'El contenido es obligatorio'}), 400

    if visibilidad not in ['publico', 'privado', 'seguidores', 'amigos']:
        return jsonify({'error': 'Visibilidad no válida'}), 400

    nueva_post = Post(
        id_usuario=usuario_id,
        contenido=contenido,
        visibilidad=visibilidad,
        imagen_url=imagen_url
    )

    db.session.add(nueva_post)
    db.session.commit()

    return jsonify({'message': 'Publicación creada con éxito'}), 201

