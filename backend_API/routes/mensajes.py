# routes/mensajes.py

from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend_API.models import db, Mensaje, User, MensajeGrupo, GrupoUsuario

mensajes_bp = Blueprint('mensajes', __name__, url_prefix='/mensajes')

@mensajes_bp.route('/directo', methods=['POST'])
@jwt_required()
def enviar_mensaje_directo():
    data = request.get_json()
    id_emisor = get_jwt_identity()
    id_receptor = data.get('id_receptor')
    mensaje = data.get('mensaje')

    nuevo_mensaje = Mensaje(
        id_emisor=id_emisor,
        id_receptor=id_receptor,
        mensaje=mensaje
    )
    db.session.add(nuevo_mensaje)
    db.session.commit()
    return jsonify(nuevo_mensaje.to_dict()), 201

@mensajes_bp.route('/directo/<int:otro_usuario_id>', methods=['GET'])
@jwt_required()
def obtener_mensajes_directos(otro_usuario_id):
    usuario_actual_id = get_jwt_identity()

    mensajes = Mensaje.query.filter(
        ((Mensaje.id_emisor == usuario_actual_id) & (Mensaje.id_receptor == otro_usuario_id)) |
        ((Mensaje.id_emisor == otro_usuario_id) & (Mensaje.id_receptor == usuario_actual_id))
    ).order_by(Mensaje.fecha_envio.asc()).all()

    return jsonify([{
        'id': m.id,
        'id_emisor': m.id_emisor,
        'id_receptor': m.id_receptor,
        'mensaje': m.mensaje,
        'fecha_envio': m.fecha_envio.isoformat()
    } for m in mensajes]), 200




@mensajes_bp.route('/grupo/<int:id_grupo>', methods=['POST'])
@jwt_required()
def enviar_mensaje_grupo(id_grupo):
    data = request.get_json()
    id_usuario = get_jwt_identity()
    mensaje = data.get('mensaje')

    # Comprobar que el usuario pertenece al grupo
    es_miembro = GrupoUsuario.query.filter_by(id_grupo=id_grupo, id_usuario=id_usuario).first()
    if not es_miembro:
        return jsonify({'error': 'No eres miembro del grupo'}), 403

    nuevo = MensajeGrupo(id_grupo=id_grupo, id_usuario=id_usuario, mensaje=mensaje)
    db.session.add(nuevo)
    db.session.commit()
    return jsonify(nuevo.to_dict()), 201

@mensajes_bp.route('/grupo/<int:id_grupo>', methods=['GET'])
@jwt_required()
def obtener_mensajes_grupo(id_grupo):
    mensajes = MensajeGrupo.query.filter_by(id_grupo=id_grupo).order_by(MensajeGrupo.fecha_envio.asc()).all()
    return jsonify([m.to_dict() for m in mensajes])