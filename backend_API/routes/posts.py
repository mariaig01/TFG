import os
import uuid
from flask import Blueprint, request, jsonify, send_file, send_from_directory, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from io import BytesIO
from werkzeug.utils import secure_filename

from backend_API.extensions import db
from backend_API.models import Post, User, Seguimiento


posts_bp = Blueprint('posts', __name__, url_prefix='/posts')

# Ruta: Crear publicación desde Flutter (JWT)
@posts_bp.route('/api/create-mobile', methods=['POST'])
@jwt_required()
def crear_post_mobile():
    """Crear publicación desde Flutter usando JWT con imagen"""
    usuario_id = int(get_jwt_identity())

    contenido = request.form.get('contenido', '').strip()
    visibilidad = request.form.get('visibilidad', 'publico')
    imagen_file = request.files.get('imagen')

    print("→ Contenido:", contenido)
    print("→ Visibilidad:", visibilidad)
    print("→ Imagen:", imagen_file.filename if imagen_file else "No imagen")

    if not contenido:
        return jsonify({'error': 'El contenido es obligatorio'}), 400

    if visibilidad not in ['publico', 'privado', 'seguidores', 'amigos']:
        return jsonify({'error': 'Visibilidad no válida'}), 400

    imagen_url = None

    if imagen_file:
        try:
            # Validar tipo MIME
            ext = imagen_file.filename.rsplit('.', 1)[-1].lower()
            if ext not in ['jpg', 'jpeg', 'png', 'gif']:
                return jsonify({'error': 'Extensión de imagen no válida'}), 400

            # Validar tamaño (máximo 5MB)
            imagen_file.seek(0, os.SEEK_END)
            file_size = imagen_file.tell()
            imagen_file.seek(0)

            if file_size > 5 * 1024 * 1024:
                return jsonify({'error': 'La imagen excede el tamaño máximo (5 MB)'}), 400

            # Crear nombre seguro y único
            filename = secure_filename(imagen_file.filename)
            ext = filename.rsplit('.', 1)[-1].lower()
            unique_name = f"{uuid.uuid4().hex}.{ext}"

            # Ruta de destino
            upload_path = os.path.join('app', 'static', 'uploads')
            os.makedirs(upload_path, exist_ok=True)

            image_path = os.path.join(upload_path, unique_name)
            imagen_file.save(image_path)

            # URL relativa accesible por el frontend
            imagen_url = f"/posts/uploads/{unique_name}"

        except Exception as e:
            return jsonify({'error': f'Error al guardar imagen: {str(e)}'}), 500

    # Crear publicación
    nueva_post = Post(
        id_usuario=usuario_id,
        contenido=contenido,
        visibilidad=visibilidad,
        imagen_url=imagen_url
    )

    db.session.add(nueva_post)
    db.session.commit()

    return jsonify({'message': 'Publicación creada con éxito'}), 201


@posts_bp.route('/api/mis-publicaciones', methods=['GET'])
@jwt_required()
def publicaciones_propias():
    user_id = int(get_jwt_identity())
    publicaciones = Post.query.filter_by(id_usuario=user_id).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"http://192.168.1.43:5000{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username
    } for p in publicaciones]), 200


@posts_bp.route('/api/seguidos-publicaciones', methods=['GET'])
@jwt_required()
def publicaciones_seguidos():
    user_id = int(get_jwt_identity())

    subquery = db.session.query(Seguimiento.id_seguido).filter(
        Seguimiento.id_seguidor == user_id,
        Seguimiento.tipo == 'seguidor'
    ).subquery()

    publicaciones = Post.query.join(User).filter(
        Post.id_usuario.in_(subquery),
        Post.visibilidad.in_(['publico', 'seguidores'])
    ).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"http://192.168.1.43:5000{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username
    } for p in publicaciones]), 200


@posts_bp.route('/api/amigos-publicaciones', methods=['GET'])
@jwt_required()
def publicaciones_amigos():
    user_id = int(get_jwt_identity())

    subquery = db.session.query(Seguimiento.id_seguido).filter(
        Seguimiento.id_seguidor == user_id,
        Seguimiento.tipo == 'amigo'
    ).subquery()

    publicaciones = Post.query.join(User).filter(
        Post.id_usuario.in_(subquery),
        Post.visibilidad.in_(['publico', 'seguidores', 'amigos'])
    ).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"http://192.168.1.43:5000{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username
    } for p in publicaciones]), 200


@posts_bp.route('/api/feed', methods=['GET'])
@jwt_required()
def feed_general():
    user_id = int(get_jwt_identity())

    # Seguidos
    seguidos_subq = db.session.query(Seguimiento.id_seguido).filter(
        Seguimiento.id_seguidor == user_id,
        Seguimiento.tipo == 'seguidor'
    ).subquery()

    publicaciones_seguidos = Post.query.join(User).filter(
        Post.id_usuario.in_(seguidos_subq),
        Post.visibilidad.in_(['publico', 'seguidores'])
    )

    # Amigos
    amigos_subq = db.session.query(Seguimiento.id_seguido).filter(
        Seguimiento.id_seguidor == user_id,
        Seguimiento.tipo == 'amigo'
    ).subquery()

    publicaciones_amigos = Post.query.join(User).filter(
        Post.id_usuario.in_(amigos_subq),
        Post.visibilidad.in_(['publico', 'seguidores', 'amigos'])
    )

    # Unir resultados, sin duplicar
    publicaciones = publicaciones_seguidos.union(publicaciones_amigos).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify({
        "posts": [{
            'id': p.id,
            'contenido': p.contenido,
            'imagen_url': f"http://192.168.1.43:5000{p.imagen_url}" if p.imagen_url else None,
            'fecha': p.fecha_publicacion.isoformat(),
            'usuario': p.usuario.username,
            'foto_perfil': p.usuario.foto_perfil  # solo si lo necesitas
        } for p in publicaciones]
    }), 200

@posts_bp.route('/uploads/<filename>')
def serve_uploaded_image(filename):
    uploads_dir = os.path.join(current_app.root_path, 'static', 'uploads')
    return send_from_directory(uploads_dir, filename)