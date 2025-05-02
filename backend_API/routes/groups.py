# routes/groups.py
import os
from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Grupo, GrupoUsuario, MensajeGrupo, User
from werkzeug.utils import secure_filename
import uuid
from datetime import datetime
from extensions import logs_collection



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
    from flask import current_app  # importar aquí, dentro de la función

    nombre = request.form.get('nombre')
    imagen_file = request.files.get('imagen')

    if not nombre:
        return jsonify({"error": "El nombre del grupo es obligatorio"}), 400

    id_creador = get_jwt_identity()
    filename = None

    if imagen_file:
        extension = imagen_file.filename.rsplit('.', 1)[-1].lower()
        filename = f"{uuid.uuid4()}.{extension}"

        upload_folder = os.path.join(current_app.root_path, 'static', 'group_images')
        os.makedirs(upload_folder, exist_ok=True)

        path = os.path.join(upload_folder, filename)
        imagen_file.save(path)

    nuevo_grupo = Grupo(
        nombre=nombre,
        descripcion=None,
        imagen=f"/groups/images/{filename}" if filename else None,
        creador=id_creador
    )

    db.session.add(nuevo_grupo)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "grupo_creado",
            "grupo_id": nuevo_grupo.id,
            "nombre": nombre,
            "creador_id": id_creador,
            "timestamp": datetime.utcnow()
        })

    return jsonify(nuevo_grupo.to_dict()), 201


@groups_bp.route('/<int:group_id>/delete', methods=['DELETE'])
@jwt_required()
def eliminar_grupo(group_id):
    user_id = int(get_jwt_identity())

    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({"error": "Grupo no encontrado"}), 404

    if grupo.creador != user_id:
        return jsonify({"error": "Solo el creador puede eliminar el grupo"}), 403

    # Eliminar imagen del grupo si existe
    if grupo.imagen:
        try:
            from pathlib import Path
            from urllib.parse import urlparse

            # Convertir la URL relativa a ruta de archivo
            relative_path = grupo.imagen.replace('/groups/images/', 'static/group_images/')
            image_path = Path(current_app.root_path) / relative_path

            if image_path.exists():
                image_path.unlink()
                print(f"🗑 Imagen del grupo eliminada: {image_path}")
            else:
                print(f"Imagen no encontrada: {image_path}")

        except Exception as e:
            print(f"Error eliminando imagen del grupo: {e}")

    # Eliminar relaciones con usuarios
    GrupoUsuario.query.filter_by(id_grupo=group_id).delete()

    # Eliminar mensajes del grupo
    MensajeGrupo.query.filter_by(id_grupo=group_id).delete()

    print(f"🧪 grupo_id: {group_id}")
    print(f"🧪 user_id del token: {user_id}")
    print(f"🧪 grupo.creador: {grupo.creador}")

    db.session.delete(grupo)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "grupo_eliminado",
            "grupo_id": group_id,
            "usuario_id": user_id,
            "timestamp": datetime.utcnow()
        })

    return jsonify({"msg": "Grupo eliminado correctamente"}), 200




@groups_bp.route('/images/<filename>')
def serve_group_image(filename):
    from flask import current_app, send_from_directory
    uploads_dir = os.path.join(current_app.root_path, 'static', 'group_images')
    return send_from_directory(uploads_dir, filename)





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
        "id_creador": creador.id,
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

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "grupo_abandonado",
            "grupo_id": group_id,
            "usuario_id": user_id,
            "timestamp": datetime.utcnow()
        })

    return jsonify({"msg": "Has abandonado el grupo"}), 200

@groups_bp.route('/<int:group_id>/join', methods=['POST'])
@jwt_required()
def unirse_a_grupo(group_id):
    user_id = get_jwt_identity()

    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({'error': 'Grupo no encontrado'}), 404

    ya_miembro = GrupoUsuario.query.filter_by(id_usuario=user_id, id_grupo=group_id).first()
    if ya_miembro:
        return jsonify({'message': 'Ya eres miembro del grupo'}), 200

    nuevo = GrupoUsuario(id_usuario=user_id, id_grupo=group_id)
    db.session.add(nuevo)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "grupo_unido",
            "grupo_id": group_id,
            "usuario_id": user_id,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': 'Te has unido al grupo correctamente'}), 200

