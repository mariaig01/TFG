from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from backend_API.models import db, User, Seguimiento

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
