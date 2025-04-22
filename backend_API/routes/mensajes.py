from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Mensaje, User, MensajeGrupo, GrupoUsuario
from extensions import socketio
from datetime import datetime
from extensions import logs_collection

mensajes_bp = Blueprint('mensajes', __name__, url_prefix='/mensajes')

@mensajes_bp.route('/directo', methods=['POST'])
@jwt_required()
def enviar_mensaje_directo():
    data = request.get_json()
    id_emisor = get_jwt_identity()
    id_receptor = data.get('id_receptor')
    mensaje = data.get('mensaje')
    id_publicacion = data.get('id_publicacion')  # opcional

    if not id_receptor:
        return jsonify({'error': 'Receptor no especificado'}), 400

    nuevo_mensaje = Mensaje(
        id_emisor=id_emisor,
        id_receptor=id_receptor,
        mensaje=mensaje,
        id_publicacion=id_publicacion
    )

    db.session.add(nuevo_mensaje)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "mensaje_directo_enviado",
            "emisor_id": id_emisor,
            "receptor_id": id_receptor,
            "mensaje": mensaje,
            "mensaje_id": nuevo_mensaje.id,
            "post_id": id_publicacion,
            "timestamp": datetime.utcnow()
        })

    socketio.emit('nuevo_mensaje', nuevo_mensaje.to_dict(), to=str(id_receptor))

    return jsonify(nuevo_mensaje.to_dict()), 201



@mensajes_bp.route('/directo/<int:otro_usuario_id>', methods=['GET'])
@jwt_required()
def obtener_mensajes_directos(otro_usuario_id):
    usuario_actual_id = get_jwt_identity()

    mensajes = Mensaje.query.filter(
        ((Mensaje.id_emisor == usuario_actual_id) & (Mensaje.id_receptor == otro_usuario_id)) |
        ((Mensaje.id_emisor == otro_usuario_id) & (Mensaje.id_receptor == usuario_actual_id))
    ).order_by(Mensaje.fecha_envio.asc()).all()

    return jsonify([m.to_dict() for m in mensajes]), 200


@mensajes_bp.route('/grupo/<int:id_grupo>', methods=['POST'])
@jwt_required()
def enviar_mensaje_grupo(id_grupo):
    data = request.get_json()
    id_usuario = get_jwt_identity()
    mensaje = data.get('mensaje', '').strip()
    id_publicacion = data.get('id_publicacion')

    # Verifica que el usuario es miembro
    es_miembro = GrupoUsuario.query.filter_by(id_grupo=id_grupo, id_usuario=id_usuario).first()
    if not es_miembro:
        return jsonify({'error': 'No eres miembro del grupo'}), 403

    nuevo = MensajeGrupo(
        id_grupo=id_grupo,
        id_usuario=id_usuario,
        mensaje=mensaje,
        id_publicacion=id_publicacion
    )

    db.session.add(nuevo)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "mensaje_grupo_enviado",
            "grupo_id": id_grupo,
            "usuario_id": id_usuario,
            "mensaje": mensaje,
            "id_publicacion": id_publicacion,
            "timestamp": datetime.utcnow()
        })

    socketio.emit('nuevo_mensaje_grupo', nuevo.to_dict(), to=f'grupo_{id_grupo}')

    return jsonify(nuevo.to_dict()), 201


@mensajes_bp.route('/grupo/<int:id_grupo>', methods=['GET'])
@jwt_required()
def obtener_mensajes_grupo(id_grupo):
    mensajes = MensajeGrupo.query.filter_by(id_grupo=id_grupo).order_by(MensajeGrupo.fecha_envio.asc()).all()
    return jsonify([m.to_dict() for m in mensajes])


@mensajes_bp.route('/usuarios-conversacion', methods=['GET'])
@jwt_required()
def obtener_usuarios_con_actividad_de_mensajes():
    user_id = int(get_jwt_identity())

    mensajes = Mensaje.query.filter(
        (Mensaje.id_emisor == user_id) | (Mensaje.id_receptor == user_id)
    ).all()

    ids_relacionados = set()
    for m in mensajes:
        if m.id_emisor != user_id:
            ids_relacionados.add(m.id_emisor)
        if m.id_receptor != user_id:
            ids_relacionados.add(m.id_receptor)

    usuarios = User.query.filter(User.id.in_(ids_relacionados)).all()

    resultado = []
    for u in usuarios:
        resultado.append({
            'id': u.id,
            'username': u.username,
            'nombre': u.nombre,
            'apellido': u.apellido,
            'foto_perfil': u.foto_perfil,
            'tipo': tipo_de_relacion(user_id, u.id)
        })

    return jsonify(resultado), 200


def tipo_de_relacion(id1, id2):
    from models import Seguimiento

    relaciones = Seguimiento.query.filter(
        ((Seguimiento.id_seguidor == id1) & (Seguimiento.id_seguido == id2)) |
        ((Seguimiento.id_seguidor == id2) & (Seguimiento.id_seguido == id1))
    ).filter(Seguimiento.estado == 'aceptada').all()

    for r in relaciones:
        if r.tipo == 'amigo':
            return 'amigo'
        elif r.tipo == 'seguidor' and r.id_seguidor == id1:
            return 'seguido'

    return 'desconocido'
