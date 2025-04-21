from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend_API.models import db, User, Seguimiento
from datetime import datetime

users_bp = Blueprint('users', __name__)

@users_bp.route('/usuarios/seguidos-y-amigos', methods=['GET'])
@jwt_required()
def obtener_seguidos_y_amigos():
    # get_jwt_identity() devuelve str porque en el login hicimos create_access_token(identity=str(user.id))
    # Lo convertimos a int para que las comparaciones funcionen correctamente
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

    # ——— AMIGOS (relación bidireccional) ———
    amigos_raw = db.session.query(Seguimiento).filter(
        ((Seguimiento.id_seguidor == id_actual) | (Seguimiento.id_seguido == id_actual)),
        Seguimiento.tipo == 'amigo',
        Seguimiento.estado == 'aceptada'
    ).all()

    amigos_list = []
    for s in amigos_raw:
        # Determinar el "otro" participante y evitar el propio usuario
        if s.id_seguidor == id_actual and s.id_seguido != id_actual:
            otro_id = s.id_seguido
        elif s.id_seguido == id_actual and s.id_seguidor != id_actual:
            otro_id = s.id_seguidor
        else:
            # descarte de relaciones incorrectas (por ejemplo, consigo mismo)
            continue

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
        'amigos':   amigos_list
    }), 200


@users_bp.route('/solicitud', methods=['POST'])
@jwt_required()
def enviar_solicitud():
    data = request.get_json()
    id_emisor = int(get_jwt_identity())
    id_receptor = int(data.get('id_receptor'))
    tipo = data.get('tipo')  # debe ser 'seguidor' o 'amigo'

    if not id_receptor or tipo not in ['seguidor', 'amigo']:
        return jsonify({'error': 'Solicitud inválida'}), 400

    # Evitar duplicados
    seguimiento_existente = Seguimiento.query.filter_by(
        id_seguidor=id_emisor,
        id_seguido=id_receptor,
        tipo=tipo
    ).first()

    if seguimiento_existente:
        return jsonify({'message': 'Ya existe la relación'}), 200

    # Insertar uno o dos seguimientos según tipo
    if tipo == 'seguidor':
        nuevo = Seguimiento(
            id_seguidor=id_emisor,
            id_seguido=id_receptor,
            fecha_inicio=datetime.utcnow(),
            tipo='seguidor'
        )
        db.session.add(nuevo)

    elif tipo == 'amigo':
        ya_son_amigos = Seguimiento.query.filter_by(
            id_seguidor=id_emisor,
            id_seguido=id_receptor,
            tipo='amigo'
        ).first()

        if ya_son_amigos:
            return jsonify({'message': 'Ya sois amigos'}), 200

        # Insertar las dos entradas cruzadas
        db.session.add_all([
            Seguimiento(
                id_seguidor=id_emisor,
                id_seguido=id_receptor,
                fecha_inicio=datetime.utcnow(),
                tipo='amigo'
            ),
            Seguimiento(
                id_seguidor=id_receptor,
                id_seguido=id_emisor,
                fecha_inicio=datetime.utcnow(),
                tipo='amigo'
            )
        ])

    db.session.commit()
    return jsonify({'message': f'Solicitud de {tipo} registrada correctamente'}), 201


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
            return jsonify({'message': 'Amistad eliminada'}), 200
        else:
            return jsonify({'message': 'No existía amistad'}), 200