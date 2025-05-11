from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import User, Grupo, GrupoUsuario, Seguimiento

general_bp = Blueprint('general', __name__, url_prefix='/api')

@general_bp.route('/buscar', methods=['GET'])
@jwt_required()
def buscar():
    query = request.args.get('q', '').strip().lower()
    if not query:
        return jsonify({'error': 'Término de búsqueda vacío'}), 400

    user_id = int(get_jwt_identity())

    # Buscar usuarios
    usuarios = User.query.filter(User.username.ilike(f'%{query}%')).all()
    resultados_usuarios = []

    for u in usuarios:
        if u.id == user_id:
            continue  # evitar que te muestres a ti mismo

        seguimiento = Seguimiento.query.filter_by(
            id_seguidor=user_id,
            id_seguido=u.id
        ).first()

        tipo = seguimiento.tipo if seguimiento else None
        estado = seguimiento.estado if seguimiento else None
        estado_seguidor = estado if seguimiento and tipo == 'seguidor' else None

        resultados_usuarios.append({
            'id': u.id,
            'username': u.username,
            'foto_perfil': f"{current_app.config['BASE_URL']}{u.foto_perfil}" if u.foto_perfil else None,
            'tipo': tipo,
            'estado': estado,
            'estado_seguidor': estado_seguidor
        })

    # Buscar grupos con info de si pertenece
    grupos = Grupo.query.filter(Grupo.nombre.ilike(f'%{query}%')).all()
    resultados_grupos = []

    for g in grupos:
        es_miembro = GrupoUsuario.query.filter_by(id_usuario=user_id, id_grupo=g.id).first() is not None
        resultados_grupos.append({
            'id': g.id,
            'nombre': g.nombre,
            'imagen': g.imagen,
            'es_miembro': es_miembro
        })

    return jsonify({
        'usuarios': resultados_usuarios,
        'grupos': resultados_grupos
    }), 200

