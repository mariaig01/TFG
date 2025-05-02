from flask import Blueprint, jsonify, request, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Seguimiento, Post, Favorito, SolicitudPrenda
from datetime import datetime
from extensions import logs_collection
import os
from werkzeug.utils import secure_filename
import uuid

users_bp = Blueprint('users', __name__, url_prefix='/usuarios')

#no se usa actualmente en el frontend
@users_bp.route('/seguidos-y-amigos', methods=['GET'])
@jwt_required()
def obtener_seguidos_y_amigos():
    id_actual = int(get_jwt_identity())

    # ——— SEGUIDOS (que NO son amigos) ———
    seguidos = db.session.query(User, Seguimiento).join(
        Seguimiento, Seguimiento.id_seguido == User.id
    ).filter(
        Seguimiento.id_seguidor == id_actual,
        Seguimiento.tipo != 'amigo',
        Seguimiento.estado == 'aceptada'
    ).all()

    seguidos_list = [{
        'id': u.id,
        'username': u.username,
        'nombre': u.nombre,
        'apellido': u.apellido,
        'foto_perfil': f"{current_app.config['BASE_URL']}{u.foto_perfil}" if u.foto_perfil else None,
        'tipo': s.tipo
    } for u, s in seguidos]

    # ——— AMIGOS (una sola vez por relación) ———
    amigos_raw = db.session.query(Seguimiento).filter(
        Seguimiento.tipo == 'amigo',
        Seguimiento.estado == 'aceptada'
    ).filter(
        ((Seguimiento.id_seguidor == id_actual) & (Seguimiento.id_seguido > id_actual)) |
        ((Seguimiento.id_seguidor < id_actual) & (Seguimiento.id_seguido == id_actual))
    ).all()

    amigos_list = []
    for s in amigos_raw:
        # Determinar el otro usuario de la amistad
        otro_id = s.id_seguidor if s.id_seguidor != id_actual else s.id_seguido
        user = User.query.get(otro_id)
        if user:
            amigos_list.append({
                'id': user.id,
                'username': user.username,
                'nombre': user.nombre,
                'apellido': user.apellido,
                'foto_perfil': f"{current_app.config['BASE_URL']}{user.foto_perfil}" if user.foto_perfil else None,
                'tipo': 'amigo'
            })

    return jsonify({
        'seguidos': seguidos_list,
        'amigos': amigos_list
    }), 200


@users_bp.route('/solicitud', methods=['POST'])
@jwt_required()
def enviar_solicitud():
    data = request.get_json()
    id_emisor = int(get_jwt_identity())
    id_receptor = int(data.get('id_receptor'))
    tipo = data.get('tipo')

    if not id_receptor or tipo not in ['seguidor', 'amigo']:
        return jsonify({'error': 'Solicitud inválida'}), 400

    if id_emisor == id_receptor:
        return jsonify({'error': 'No puedes establecer relación contigo mismo'}), 400

    # Comprobar si ya hay una relación pendiente o aceptada
    existente = Seguimiento.query.filter_by(
        id_seguidor=id_emisor,
        id_seguido=id_receptor,
        tipo=tipo
    ).first()

    if existente:
        return jsonify({'message': 'La solicitud ya existe'}), 200

    nueva = Seguimiento(
        id_seguidor=id_emisor,
        id_seguido=id_receptor,
        tipo=tipo,
        estado='pendiente',
        fecha_inicio=datetime.utcnow()
    )

    db.session.add(nueva)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "solicitud_enviada",
            "tipo": tipo,
            "emisor_id": id_emisor,
            "receptor_id": id_receptor,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': f'Solicitud de {tipo} enviada correctamente'}), 201






@users_bp.route('/rechazar', methods=['POST'])
@jwt_required()
def rechazar_solicitud():
    data = request.get_json()
    id_receptor = int(get_jwt_identity())  # quien rechaza
    id_emisor = int(data.get('id_emisor'))
    tipo = data.get('tipo')

    if not id_emisor or tipo not in ['seguidor', 'amigo']:
        return jsonify({'error': 'Solicitud inválida'}), 400

    solicitud = Seguimiento.query.filter_by(
        id_seguidor=id_emisor,
        id_seguido=id_receptor,
        tipo=tipo,
        estado='pendiente'
    ).first()

    if not solicitud:
        return jsonify({'error': 'No hay solicitud pendiente'}), 404

    db.session.delete(solicitud)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "solicitud_rechazada",
            "tipo": tipo,
            "usuario_id": id_receptor,
            "otro_usuario_id": id_emisor,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': f'Solicitud de {tipo} rechazada correctamente'}), 200




@users_bp.route('/aceptar', methods=['POST'])
@jwt_required()
def aceptar_solicitud():
    data = request.get_json()
    id_receptor = int(get_jwt_identity())  # quien acepta
    id_emisor = int(data.get('id_emisor'))
    tipo = data.get('tipo')

    if not id_emisor or tipo not in ['seguidor', 'amigo']:
        return jsonify({'error': 'Solicitud inválida'}), 400

    solicitud = Seguimiento.query.filter_by(
        id_seguidor=id_emisor,
        id_seguido=id_receptor,
        tipo=tipo,
        estado='pendiente'
    ).first()

    if not solicitud:
        return jsonify({'error': 'No hay solicitud pendiente'}), 404

    solicitud.estado = 'aceptada'
    solicitud.fecha_inicio = datetime.utcnow()

    # Si es amistad, crear también la relación inversa
    if tipo == 'amigo':
        ya_existe = Seguimiento.query.filter_by(
            id_seguidor=id_receptor,
            id_seguido=id_emisor,
            tipo='amigo'
        ).first()

        if not ya_existe:
            reciproco = Seguimiento(
                id_seguidor=id_receptor,
                id_seguido=id_emisor,
                tipo='amigo',
                estado='aceptada',
                fecha_inicio=datetime.utcnow()
            )
            db.session.add(reciproco)

    db.session.commit()

    return jsonify({'message': f'Solicitud de {tipo} aceptada'}), 200




@users_bp.route('/relacion', methods=['DELETE'])
@jwt_required()
def eliminar_relacion():
    data = request.get_json()
    id_emisor = int(get_jwt_identity())
    id_receptor = int(data.get('id_receptor'))
    tipo = data.get('tipo')

    if not id_receptor or tipo not in ['seguidor', 'amigo']:
        return jsonify({'error': 'Solicitud inválida'}), 400

    if tipo == 'seguidor':
        relacion = Seguimiento.query.filter_by(
            id_seguidor=id_emisor,
            id_seguido=id_receptor,
            tipo='seguidor'
        ).first()

        if relacion:
            db.session.delete(relacion)
            db.session.commit()

            if logs_collection is not None:
                logs_collection.insert_one({
                    "evento": "relacion_eliminada",
                    "tipo": "seguidor",
                    "usuario_id": id_emisor,
                    "otro_usuario_id": id_receptor,
                    "timestamp": datetime.utcnow()
                })

            return jsonify({'message': 'Dejaste de seguir al usuario'}), 200
        else:
            return jsonify({'message': 'No existía la relación'}), 200

    elif tipo == 'amigo':
        # Eliminar relación en ambos sentidos
        relaciones = Seguimiento.query.filter(
            ((Seguimiento.id_seguidor == id_emisor) & (Seguimiento.id_seguido == id_receptor)) |
            ((Seguimiento.id_seguidor == id_receptor) & (Seguimiento.id_seguido == id_emisor)),
            Seguimiento.tipo == 'amigo'
        ).all()

        if relaciones:
            for r in relaciones:
                db.session.delete(r)
            db.session.commit()

            if logs_collection is not None:
                logs_collection.insert_one({
                    "evento": "relacion_eliminada",
                    "tipo": "amigo",
                    "usuario_id": id_emisor,
                    "otro_usuario_id": id_receptor,
                    "timestamp": datetime.utcnow()
                })

            return jsonify({'message': 'Amistad eliminada'}), 200
        else:
            return jsonify({'message': 'No existía amistad'}), 200



@users_bp.route('/solicitudes-recibidas', methods=['GET'])
@jwt_required()
def solicitudes_recibidas():
    id_actual = int(get_jwt_identity())
    resultado = []

    # 🟣 1. Solicitudes de seguimiento / amistad
    seguimientos = Seguimiento.query.filter_by(
        id_seguido=id_actual,
        estado='pendiente'
    ).all()

    for s in seguimientos:
        emisor = User.query.get(s.id_seguidor)
        if not emisor:
            continue
        resultado.append({
            'id': emisor.id,
            'username': emisor.username,
            'foto_perfil': emisor.foto_perfil,
            'tipo': s.tipo,  # 'amigo' o 'seguidor'
            'fecha': s.fecha_inicio.isoformat()
        })

    # 🟢 2. Solicitudes de prendas
    solicitudes_prenda = SolicitudPrenda.query.filter_by(
        id_destinatario=id_actual,
        estado='pendiente'
    ).all()

    for sp in solicitudes_prenda:
        remitente = User.query.get(sp.id_remitente)
        if not remitente:
            continue
        resultado.append({
            'id': sp.id,  # ID de la solicitud (no del usuario)
            'username': remitente.username,
            'foto_perfil': remitente.foto_perfil,
            'tipo': 'prenda',
            'fecha': sp.fecha_solicitud.isoformat()
        })

    return jsonify(resultado), 200



@users_bp.route('/<int:user_id>', methods=['GET'])
@jwt_required()
def obtener_usuario_por_id(user_id):
    usuario = User.query.get(user_id)
    if not usuario:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    return jsonify(usuario.to_dict()), 200


@users_bp.route('/<int:user_id>/seguidores', methods=['GET'])
@jwt_required()
def obtener_seguidores(user_id):
    relaciones = Seguimiento.query.filter_by(
        id_seguido=user_id,
        estado='aceptada'
    ).filter(Seguimiento.tipo != 'amigo').all()

    seguidores = [r.id_seguidor for r in relaciones]
    usuarios = User.query.filter(User.id.in_(seguidores)).all()
    return jsonify([u.to_dict() for u in usuarios]), 200



@users_bp.route('/<int:user_id>/seguidos', methods=['GET'])
@jwt_required()
def obtener_seguidos(user_id):
    relaciones = Seguimiento.query.filter_by(
        id_seguidor=user_id,
        estado='aceptada'
    ).filter(Seguimiento.tipo != 'amigo').all()

    seguidos = [r.id_seguido for r in relaciones]
    usuarios = User.query.filter(User.id.in_(seguidos)).all()
    return jsonify([u.to_dict() for u in usuarios]), 200



@users_bp.route('/<int:user_id>/amigos', methods=['GET'])
@jwt_required()
def obtener_amigos(user_id):
    relaciones_yo = Seguimiento.query.filter_by(
        id_seguidor=user_id,
        tipo='amigo',
        estado='aceptada'
    ).all()

    posibles_amigos_ids = [r.id_seguido for r in relaciones_yo]

    # Verifica reciprocidad
    relaciones_ellos = Seguimiento.query.filter(
        Seguimiento.id_seguidor.in_(posibles_amigos_ids),
        Seguimiento.id_seguido == user_id,
        Seguimiento.tipo == 'amigo',
        Seguimiento.estado == 'aceptada'
    ).all()

    amigos_ids = [r.id_seguidor for r in relaciones_ellos]
    usuarios = User.query.filter(User.id.in_(amigos_ids)).all()
    return jsonify([u.to_dict() for u in usuarios]), 200


@users_bp.route('/subir-imagen-perfil', methods=['POST'])
@jwt_required()
def subir_imagen_perfil():


    usuario_id = int(get_jwt_identity())
    usuario = User.query.get(usuario_id)

    if not usuario:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    imagen_file = request.files.get('imagen')
    if not imagen_file:
        return jsonify({'error': 'No se recibió ninguna imagen'}), 400

    try:
        # Validar extensión
        ext = imagen_file.filename.rsplit('.', 1)[-1].lower()
        if ext not in ['jpg', 'jpeg', 'png', 'gif']:
            return jsonify({'error': 'Extensión de imagen no válida'}), 400

        # Validar tamaño (máximo 5MB)
        imagen_file.seek(0, os.SEEK_END)
        file_size = imagen_file.tell()
        imagen_file.seek(0)
        if file_size > 5 * 1024 * 1024:
            return jsonify({'error': 'La imagen excede el tamaño máximo (5 MB)'}), 400

        # Eliminar foto anterior si existe
        if usuario.foto_perfil:
            try:
                from pathlib import Path
                relative_path = usuario.foto_perfil.replace('/usuarios/profile-images/', 'static/profile_images/')
                old_path = Path(current_app.root_path) / relative_path
                if old_path.exists():
                    old_path.unlink()
            except Exception as e:
                print(f"Error eliminando imagen anterior: {e}")

        # Crear nombre único y ruta
        filename = secure_filename(imagen_file.filename)
        unique_name = f"{uuid.uuid4().hex}.{ext}"

        upload_path = os.path.join(current_app.root_path, 'static', 'profile_images')
        os.makedirs(upload_path, exist_ok=True)

        image_path = os.path.join(upload_path, unique_name)
        imagen_file.save(image_path)

        # Actualizar usuario
        usuario.foto_perfil = f"/usuarios/profile-images/{unique_name}"
        db.session.commit()

        return jsonify({'foto_perfil': usuario.foto_perfil}), 200

    except Exception as e:
        return jsonify({'error': f'Error al guardar imagen: {str(e)}'}), 500



@users_bp.route('/profile-images/<filename>')
def serve_profile_image(filename):
    from flask import current_app, send_from_directory
    upload_path = os.path.join(current_app.root_path, 'static', 'profile_images')
    return send_from_directory(upload_path, filename)


@users_bp.route('/mis-publicaciones', methods=['GET'])
@jwt_required()
def publicaciones_propias():
    user_id = int(get_jwt_identity())
    usuario = User.query.get(user_id)

    publicaciones = Post.query.filter_by(id_usuario=user_id).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username,
        'foto_perfil': f"{current_app.config['BASE_URL']}{usuario.foto_perfil}" if usuario.foto_perfil else None,
        'likes_count': len(p.likes),
        'ha_dado_like': any(l.id_usuario == user_id for l in p.likes),
        'tipo_relacion': 'propia',
        'id_usuario': p.id_usuario
    } for p in publicaciones]), 200


@users_bp.route('/seguidos-publicaciones', methods=['GET'])
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
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username
    } for p in publicaciones]), 200


@users_bp.route('/amigos-publicaciones', methods=['GET'])
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
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username
    } for p in publicaciones]), 200


@users_bp.route('/publicaciones-guardadas', methods=['GET'])
@jwt_required()
def publicaciones_guardadas():
    user_id = int(get_jwt_identity())

    favoritos = Favorito.query.filter_by(id_usuario=user_id).filter(Favorito.id_publicacion != None).all()
    publicaciones = [f.id_publicacion for f in favoritos]

    from models import Post
    posts = Post.query.filter(Post.id.in_(publicaciones)).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username,
        'id_usuario': p.id_usuario,
        'foto_perfil': f"{current_app.config['BASE_URL']}{p.usuario.foto_perfil}" if p.usuario.foto_perfil else None,
        'likes_count': len(p.likes),
        'ha_dado_like': any(l.id_usuario == user_id for l in p.likes),
        'tipo_relacion': 'guardado',
        'guardado': Favorito.query.filter_by(id_usuario=user_id, id_publicacion=p.id).first() is not None
    } for p in posts]), 200


@users_bp.route('/publicaciones/usuario/<int:user_id>', methods=['GET'])
@jwt_required()
def publicaciones_de_usuario(user_id):
    usuario = User.query.get(user_id)
    if not usuario:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    publicaciones = Post.query.filter_by(id_usuario=user_id).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': usuario.username,
        'foto_perfil': f"{current_app.config['BASE_URL']}{usuario.foto_perfil}" if usuario.foto_perfil else None,
        'likes_count': len(p.likes),
        'ha_dado_like': False,  # Opcional: puedes calcularlo si es el usuario autenticado
    } for p in publicaciones]), 200


@users_bp.route('/<int:user_id>/relacion', methods=['GET'])
@jwt_required()
def obtener_relacion_usuario(user_id):
    actual_id = int(get_jwt_identity())

    amistad = Seguimiento.query.filter(
        ((Seguimiento.id_seguidor == actual_id) & (Seguimiento.id_seguido == user_id)) |
        ((Seguimiento.id_seguidor == user_id) & (Seguimiento.id_seguido == actual_id)),
        Seguimiento.tipo == 'amigo',
        Seguimiento.estado == 'aceptada'
    ).first()

    seguimiento = Seguimiento.query.filter_by(
        id_seguidor=actual_id,
        id_seguido=user_id,
        tipo='seguidor'
    ).first()

    response = {}

    if amistad:
        response['relacion'] = 'amigo'
        response['estado'] = 'aceptada'
    elif seguimiento:
        response['relacion'] = 'seguidor'
        response['estado'] = seguimiento.estado
    else:
        response['relacion'] = None
        response['estado'] = None

    solicitud_seguidor = Seguimiento.query.filter_by(
        id_seguidor=actual_id,
        id_seguido=user_id,
        tipo='seguidor',
        estado='pendiente'
    ).first()

    if solicitud_seguidor:
        response['estado_seguidor'] = 'pendiente'

    return jsonify(response), 200

@users_bp.route('/editar', methods=['PUT'])
@jwt_required()
def editar_usuario():
    usuario_id = int(get_jwt_identity())
    user = User.query.get(usuario_id)

    if not user:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    data = request.get_json()

    nuevo_username = data.get('username', user.username)

    # Comprobar si el nuevo username está en uso por otro usuario
    if nuevo_username != user.username:
        username_existente = User.query.filter_by(username=nuevo_username).first()
        if username_existente:
            return jsonify({'error': 'El nombre de usuario ya está en uso'}), 400

    # Actualizamos los campos
    user.nombre = data.get('nombre', user.nombre)
    user.apellido = data.get('apellido', user.apellido)
    user.bio = data.get('bio', user.bio)
    user.username = nuevo_username
    user.fecha_modificacion = datetime.utcnow()

    db.session.commit()

    return jsonify({'message': 'Perfil actualizado con éxito'}), 200
