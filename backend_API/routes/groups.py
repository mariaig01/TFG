# routes/groups.py
import os
from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend_API.models import db, Grupo, GrupoUsuario, MensajeGrupo, User
from werkzeug.utils import secure_filename
import uuid
from datetime import datetime

UPLOAD_FOLDER = 'static/group_images'

groups_bp = Blueprint('groups', __name__, url_prefix='/groups')

# GET /groups/user-groups
@groups_bp.route('/user-groups', methods=['GET'])
@jwt_required()
def get_user_groups():
    user_id = get_jwt_identity()
    grupos_usuario = GrupoUsuario.query.filter_by(id_usuario=user_id).all()
    grupos = [gu.grupo.to_dict() for gu in grupos_usuario]
    return jsonify(grupos), 200


@groups_bp.route('/create', methods=['POST'])
@jwt_required()
def crear_grupo():
    nombre = request.form.get('nombre')
    imagen_file = request.files.get('imagen')  # Aquí obtenemos el archivo

    if not nombre:
        return jsonify({"error": "El nombre del grupo es obligatorio"}), 400

    id_creador = get_jwt_identity()
    filename = None

    if imagen_file:
        extension = imagen_file.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4()}.{extension}"
        path = os.path.join(UPLOAD_FOLDER, filename)
        os.makedirs(UPLOAD_FOLDER, exist_ok=True)
        imagen_file.save(path)

    nuevo_grupo = Grupo(
        nombre=nombre,
        descripcion=None,
        imagen=f"/groups/images/{filename}" if filename else None,
        creador=id_creador
    )

    db.session.add(nuevo_grupo)
    db.session.commit()

    return jsonify(nuevo_grupo.to_dict()), 201


@groups_bp.route('/images/<filename>')
def serve_group_image(filename):
    from flask import current_app, send_from_directory
    uploads_dir = os.path.join(current_app.root_path, 'static', 'group_images')
    return send_from_directory(uploads_dir, filename)



@groups_bp.route('/<int:group_id>/messages', methods=['POST'])
@jwt_required()
def enviar_mensaje_grupo(group_id):
    usuario_id = get_jwt_identity()
    data = request.get_json()
    contenido = data.get('mensaje', '').strip()

    if not contenido:
        return jsonify({'error': 'El mensaje no puede estar vacío'}), 400

    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({'error': 'Grupo no encontrado'}), 404

    miembro = GrupoUsuario.query.filter_by(id_usuario=usuario_id, id_grupo=group_id).first()
    if not miembro:
        return jsonify({'error': 'No perteneces a este grupo'}), 403

    mensaje = MensajeGrupo(
        mensaje=contenido,
        fecha_envio=datetime.utcnow(),
        id_usuario=usuario_id,
        id_grupo=group_id
    )

    db.session.add(mensaje)
    db.session.commit()

    return jsonify(mensaje.to_dict()), 201



@groups_bp.route('/<int:group_id>/messages', methods=['GET'])
@jwt_required()
def obtener_mensajes_grupo(group_id):
    usuario_id = get_jwt_identity()

    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({"error": "Grupo no encontrado"}), 404

    miembro = GrupoUsuario.query.filter_by(id_usuario=usuario_id, id_grupo=group_id).first()
    if not miembro:
        return jsonify({"error": "No perteneces a este grupo"}), 403

    mensajes = MensajeGrupo.query.filter_by(id_grupo=group_id)\
        .order_by(MensajeGrupo.fecha_envio.asc()).all()

    return jsonify([m.to_dict() for m in mensajes]), 200

@groups_bp.route('/<int:group_id>/info', methods=['GET'])
@jwt_required()
def info_grupo(group_id):
    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({"error": "Grupo no encontrado"}), 404

    creador = User.query.get(grupo.creador)
    miembros = GrupoUsuario.query.filter_by(id_grupo=group_id).count()

    return jsonify({
        "creador": creador.username if creador else "Desconocido",
        "num_miembros": miembros
    }), 200


@groups_bp.route('/<int:group_id>/leave', methods=['POST'])
@jwt_required()
def abandonar_grupo(group_id):
    user_id = get_jwt_identity()

    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({"error": "Grupo no encontrado"}), 404

    miembro = GrupoUsuario.query.filter_by(id_usuario=user_id, id_grupo=group_id).first()
    if not miembro:
        return jsonify({"error": "No perteneces a este grupo"}), 403

    db.session.delete(miembro)
    db.session.commit()

    return jsonify({"msg": "Has abandonado el grupo"}), 200
