from flask import Blueprint, jsonify, request
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Seguimiento
from datetime import datetime
from extensions import logs_collection

users_bp = Blueprint('users', __name__, url_prefix='/usuarios')

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
        'foto_perfil': u.foto_perfil,
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
                'foto_perfil': user.foto_perfil,
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

    solicitudes = Seguimiento.query.filter_by(
        id_seguido=id_actual,
        estado='pendiente'
    ).all()

    resultado = []
    for s in solicitudes:
        emisor = User.query.get(s.id_seguidor)
        if not emisor:
            continue
        resultado.append({
            'id': emisor.id,
            'username': emisor.username,
            'foto_perfil': emisor.foto_perfil,
            'tipo': s.tipo,       # 'amigo' o 'seguidor'
            'fecha': s.fecha_inicio.isoformat()
        })

    return jsonify(resultado), 200
