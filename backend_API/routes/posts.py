import os
import uuid
from flask import Blueprint, request, jsonify, send_from_directory, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from extensions import socketio
from extensions import db, logs_collection
from models import Post, User, Seguimiento, Comentario, Like, Mensaje, MensajeGrupo
from sqlalchemy import select, union_all
from datetime import datetime


posts_bp = Blueprint('posts', __name__, url_prefix='/posts')

# Ruta: Crear publicación desde Flutter (JWT)
@posts_bp.route('/api/create-mobile', methods=['POST'])
@jwt_required()
def crear_post_mobile():
    usuario_id = int(get_jwt_identity())

    contenido = request.form.get('contenido', '').strip()
    visibilidad = request.form.get('visibilidad', 'publico')
    imagen_file = request.files.get('imagen')


    if not contenido:
        return jsonify({'error': 'El contenido es obligatorio'}), 400

    if visibilidad not in ['publico', 'privado', 'seguidores', 'amigos']:
        return jsonify({'error': 'Visibilidad no válida'}), 400

    if not imagen_file:
        return jsonify({'error': 'La imagen es obligatoria'}), 400

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

        # Crear nombre seguro y único
        filename = secure_filename(imagen_file.filename)
        unique_name = f"{uuid.uuid4().hex}.{ext}"

        # Ruta de destino
        upload_path = os.path.join(current_app.root_path, 'static', 'uploads')
        os.makedirs(upload_path, exist_ok=True)

        image_path = os.path.join(upload_path, unique_name)
        imagen_file.save(image_path)

        # URL accesible desde Flutter
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

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "publicacion_creada",
            "usuario_id": usuario_id,
            "contenido": contenido,
            "visibilidad": visibilidad,
            "imagen_url": imagen_url,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': 'Publicación creada con éxito'}), 201



@posts_bp.route('/api/feed', methods=['GET'])
@jwt_required()
def feed_general():
    user_id = int(get_jwt_identity())

    # Obtener IDs de seguidos
    seguidos_ids = db.session.query(Seguimiento.id_seguido).filter(
        Seguimiento.id_seguidor == user_id,
        Seguimiento.tipo == 'seguidor',
        Seguimiento.estado == 'aceptada'
    ).subquery()

    # Obtener IDs de amigos bidireccionales únicos
    amigos_1 = db.session.query(Seguimiento.id_seguidor).filter(
        Seguimiento.id_seguido == user_id,
        Seguimiento.tipo == 'amigo',
        Seguimiento.estado == 'aceptada'
    )

    amigos_2 = db.session.query(Seguimiento.id_seguido).filter(
        Seguimiento.id_seguidor == user_id,
        Seguimiento.tipo == 'amigo',
        Seguimiento.estado == 'aceptada'
    )

    amigos_ids = [row[0] for row in amigos_1.union_all(amigos_2).all()]

    # --- Construir los tres subconjuntos según visibilidad ---

    publicaciones_publicas = Post.query.join(User).filter(
        ((Post.id_usuario.in_(select(seguidos_ids.c.id_seguido))) |
         (Post.id_usuario.in_(amigos_ids))),
        Post.visibilidad == 'publico'
    )

    publicaciones_seguidores = Post.query.join(User).filter(
        Post.id_usuario.in_(select(seguidos_ids.c.id_seguido)),
        Post.visibilidad == 'seguidores'
    )

    publicaciones_amigos = Post.query.join(User).filter(
        Post.id_usuario.in_(amigos_ids),
        Post.visibilidad == 'amigos'
    )

    # Unir todo y ordenar
    publicaciones = publicaciones_publicas.union_all(
        publicaciones_seguidores
    ).union_all(
        publicaciones_amigos
    ).order_by(Post.fecha_publicacion.desc()).all()

    # Construir respuesta
    posts_data = []
    for p in publicaciones:
        autor_id = p.id_usuario

        tipo_relacion = ''
        seguimientos = Seguimiento.query.filter(
            ((Seguimiento.id_seguidor == user_id) & (Seguimiento.id_seguido == autor_id)) |
            ((Seguimiento.id_seguidor == autor_id) & (Seguimiento.id_seguido == user_id))
        ).filter(Seguimiento.estado == 'aceptada').all()

        for s in seguimientos:
            if s.tipo == 'amigo':
                tipo_relacion = 'amigo'
                break
            elif s.tipo == 'seguidor' and s.id_seguidor == user_id:
                tipo_relacion = 'seguido'

        posts_data.append({
            'id': p.id,
            'contenido': p.contenido,
            'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
            'fecha': p.fecha_publicacion.isoformat(),
            'usuario': p.usuario.username,
            'foto_perfil': p.usuario.foto_perfil,
            'likes_count': len(p.likes),
            'ha_dado_like': any(l.id_usuario == user_id for l in p.likes),
            'tipo_relacion': tipo_relacion
        })

    return jsonify({"posts": posts_data}), 200



@posts_bp.route('/api/mis-publicaciones', methods=['GET'])
@jwt_required()
def publicaciones_propias():
    user_id = int(get_jwt_identity())
    publicaciones = Post.query.filter_by(id_usuario=user_id).order_by(Post.fecha_publicacion.desc()).all()

    return jsonify([{
        'id': p.id,
        'contenido': p.contenido,
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
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
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
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
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'fecha': p.fecha_publicacion.isoformat(),
        'usuario': p.usuario.username
    } for p in publicaciones]), 200




@posts_bp.route('/uploads/<filename>')
def serve_uploaded_image(filename):
    uploads_dir = os.path.join(current_app.root_path, 'static', 'uploads')
    return send_from_directory(uploads_dir, filename)


@posts_bp.route('/api/<int:post_id>/comments', methods=['GET'])
@jwt_required()
def obtener_comentarios(post_id):
    comentarios = Comentario.query.filter_by(id_publicacion=post_id).order_by(Comentario.fecha_comentario.desc()).all()
    return jsonify([{
        'id': c.id,
        'post_id': c.id_publicacion,
        'autor': c.usuario.username,
        'contenido': c.texto,
        'fecha': c.fecha_comentario.isoformat()
    } for c in comentarios]), 200


@posts_bp.route('/api/<int:post_id>/comments', methods=['POST'])
@jwt_required()
def crear_comentario(post_id):
    user_id = int(get_jwt_identity())
    data = request.get_json()
    texto = data.get('contenido', '').strip()

    if not texto:
        return jsonify({'error': 'El comentario no puede estar vacío'}), 400

    nuevo_comentario = Comentario(
        id_publicacion=post_id,
        id_usuario=user_id,
        texto=texto
    )
    db.session.add(nuevo_comentario)
    db.session.commit()

    comentario_dict = {
        'id': nuevo_comentario.id,
        'post_id': post_id,
        'autor': nuevo_comentario.usuario.username,
        'contenido': nuevo_comentario.texto,
        'fecha': nuevo_comentario.fecha_comentario.isoformat()
    }

    socketio.emit(f'nuevo_comentario_{post_id}', comentario_dict)

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "comentario_creado",
            "usuario_id": user_id,
            "post_id": post_id,
            "contenido": texto,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': 'Comentario creado exitosamente'}), 201


@posts_bp.route('/api/<int:post_id>/like', methods=['POST'])
@jwt_required()
def toggle_like(post_id):
    user_id = int(get_jwt_identity())

    # Verifica si la publicación existe
    publicacion = Post.query.get(post_id)
    if not publicacion:
        return jsonify({'error': 'Publicación no encontrada'}), 404

    # Comprueba si ya existe un like
    like_existente = Like.query.filter_by(
        id_usuario=user_id,
        id_publicacion=post_id
    ).first()

    if like_existente:
        db.session.delete(like_existente)
        db.session.commit()

        if logs_collection is not None:
            logs_collection.insert_one({
                "evento": "like_eliminado",
                "usuario_id": user_id,
                "post_id": post_id,
                "timestamp": datetime.utcnow()
            })

        return jsonify({'message': 'Like eliminado'}), 200
    else:
        nuevo_like = Like(
            id_usuario=user_id,
            id_publicacion=post_id,
            fecha_creacion=datetime.utcnow()
        )
        db.session.add(nuevo_like)
        db.session.commit()

        if logs_collection is not None:
            logs_collection.insert_one({
                "evento": "like_eliminado",
                "usuario_id": user_id,
                "post_id": post_id,
                "timestamp": datetime.utcnow()
            })

        return jsonify({'message': 'Like añadido'}), 201





@posts_bp.route('/api/<int:post_id>/enviar-grupo/<int:group_id>', methods=['POST'])
@jwt_required()
def enviar_publicacion_a_grupo(post_id, group_id):
    user_id = int(get_jwt_identity())
    data = request.get_json()
    mensaje = data.get('mensaje', '').strip()

    # Comprobar que el grupo existe
    grupo = Grupo.query.get(group_id)
    if not grupo:
        return jsonify({'error': 'Grupo no encontrado'}), 404

    # Comprobar que el usuario pertenece al grupo
    miembro = GrupoUsuario.query.filter_by(id_grupo=group_id, id_usuario=user_id).first()
    if not miembro:
        return jsonify({'error': 'No perteneces a este grupo'}), 403

    # Adjuntar el ID de la publicación como parte del mensaje
    mensaje_con_post = f"📎 Publicación {post_id}\n{mensaje}" if mensaje else f"📎 Publicación {post_id}"

    nuevo_mensaje = MensajeGrupo(
        mensaje=mensaje_con_post,
        fecha_envio=datetime.utcnow(),
        id_usuario=user_id,
        id_grupo=group_id
    )

    db.session.add(nuevo_mensaje)
    db.session.commit()

    return jsonify(nuevo_mensaje.to_dict()), 201