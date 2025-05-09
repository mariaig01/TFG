import os
import uuid
from flask import Blueprint, request, jsonify, send_from_directory, current_app, url_for
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from extensions import socketio
from extensions import db, logs_collection
from models import Post, User, Seguimiento, Comentario, Like, Favorito
from sqlalchemy import select, union_all
from datetime import datetime



posts_bp = Blueprint('posts', __name__, url_prefix='/posts')

# Ruta: Crear publicación desde Flutter (JWT)
@posts_bp.route('/create-mobile', methods=['POST'])
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



@posts_bp.route('/feed', methods=['GET'])
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
            'id_usuario': autor_id,
            'contenido': p.contenido,
            'visibilidad': p.visibilidad,
            'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
            'fecha': p.fecha_publicacion.isoformat(),
            'usuario': p.usuario.username,
            'foto_perfil': f"{current_app.config['BASE_URL']}{p.usuario.foto_perfil}" if p.usuario.foto_perfil else None,
            'likes_count': Like.query.filter_by(id_publicacion=p.id).count(),

            'ha_dado_like': any(l.id_usuario == user_id for l in p.likes),
            'tipo_relacion': tipo_relacion,
            'guardado': Favorito.query.filter_by(id_usuario=user_id, id_publicacion=p.id).first() is not None
        })

    return jsonify({"posts": posts_data}), 200








@posts_bp.route('/uploads/<filename>')
def serve_uploaded_image(filename):
    uploads_dir = os.path.join(current_app.root_path, 'static', 'uploads')
    return send_from_directory(uploads_dir, filename)


@posts_bp.route('/<int:post_id>/comments', methods=['GET'])
@jwt_required()
def obtener_comentarios(post_id):
    comentarios = Comentario.query.filter_by(id_publicacion=post_id).order_by(Comentario.fecha_comentario.desc()).all()

    comentarios_json = []
    for c in comentarios:
        usuario = User.query.get(c.id_usuario)

        username = usuario.username if usuario else "Desconocido"

        # Extraer nombre de archivo de foto
        if usuario and usuario.foto_perfil:
            filename = usuario.foto_perfil.replace("/usuarios/profile-images/", "")
            foto_url = url_for("users.serve_profile_image", filename=filename, _external=True)
        else:
            foto_url = url_for("users.serve_profile_image", filename="default.png", _external=True)

        comentarios_json.append({
            'id': c.id,
            'post_id': c.id_publicacion,
            'autor': username,
            'contenido': c.texto,
            'fecha': c.fecha_comentario.isoformat(),
            'foto_autor': foto_url
        })

    return jsonify(comentarios_json), 200



@posts_bp.route('/<int:post_id>/comments', methods=['POST'])
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


@posts_bp.route('/<int:post_id>/like', methods=['POST'])
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

        # Log correcto
        if logs_collection is not None:
            logs_collection.insert_one({
                "evento": "like_eliminado",
                "usuario_id": user_id,
                "post_id": post_id,
                "timestamp": datetime.utcnow()
            })

        nuevo_estado = False
    else:
        nuevo_like = Like(
            id_usuario=user_id,
            id_publicacion=post_id,
            fecha_creacion=datetime.utcnow()
        )
        db.session.add(nuevo_like)
        db.session.commit()

        # Log correcto
        if logs_collection is not None:
            logs_collection.insert_one({
                "evento": "like_añadido",
                "usuario_id": user_id,
                "post_id": post_id,
                "timestamp": datetime.utcnow()
            })

        nuevo_estado = True

    # Contar likes actuales
    total_likes = Like.query.filter_by(id_publicacion=post_id).count()

    return jsonify({
        'message': 'Like actualizado',
        'ha_dado_like': nuevo_estado,
        'likes_count': total_likes
    }), 200




@posts_bp.route('/<int:post_id>/guardar-toggle', methods=['POST'])
@jwt_required()
def toggle_guardado_publicacion(post_id):
    user_id = int(get_jwt_identity())

    favorito = Favorito.query.filter_by(id_usuario=user_id, id_publicacion=post_id).first()

    if favorito:
        db.session.delete(favorito)
        db.session.commit()
        return jsonify({'message': 'Desguardado', 'guardado': False}), 200
    else:
        nuevo = Favorito(id_usuario=user_id, id_publicacion=post_id)
        db.session.add(nuevo)
        db.session.commit()
        return jsonify({'message': 'Guardado', 'guardado': True}), 201


@posts_bp.route('/<int:post_id>/eliminar', methods=['DELETE'])
@jwt_required()
def eliminar_publicacion(post_id):
    user_id = int(get_jwt_identity())

    publicacion = Post.query.filter_by(id=post_id, id_usuario=user_id).first()

    if not publicacion:
        return jsonify({'error': 'Publicación no encontrada o no autorizada'}), 404

    # Eliminar imagen física si existe
    if publicacion.imagen_url:
        try:
            nombre_archivo = publicacion.imagen_url.split('/')[-1]
            ruta_imagen = os.path.join(current_app.root_path, 'static', 'uploads', nombre_archivo)
            if os.path.exists(ruta_imagen):
                os.remove(ruta_imagen)
        except Exception as e:
            print(f" Error al eliminar imagen: {e}")

    db.session.delete(publicacion)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "publicacion_eliminada",
            "usuario_id": user_id,
            "post_id": post_id,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': 'Publicación eliminada correctamente'}), 200



@posts_bp.route('/<int:post_id>/editar', methods=['PUT'])
@jwt_required()
def editar_publicacion(post_id):
    user_id = int(get_jwt_identity())
    data = request.get_json()

    publicacion = Post.query.filter_by(id=post_id, id_usuario=user_id).first()
    if not publicacion:
        return jsonify({'error': 'Publicación no encontrada o no autorizada'}), 404

    nuevo_contenido = data.get('contenido', '').strip()
    nueva_visibilidad = data.get('visibilidad', publicacion.visibilidad)

    if not nuevo_contenido:
        return jsonify({'error': 'El contenido no puede estar vacío'}), 400

    if nueva_visibilidad not in ['publico', 'privado', 'seguidores', 'amigos']:
        return jsonify({'error': 'Visibilidad no válida'}), 400

    publicacion.contenido = nuevo_contenido
    publicacion.visibilidad = nueva_visibilidad

    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "publicacion_editada",
            "usuario_id": user_id,
            "post_id": post_id,
            "nuevo_contenido": nuevo_contenido,
            "nueva_visibilidad": nueva_visibilidad,
            "timestamp": datetime.utcnow()
        })


    return jsonify({'message': 'Publicación actualizada con éxito'}), 200
