from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required
from backend_API.models import User, Grupo, GrupoUsuario, Seguimiento
from flask_jwt_extended import jwt_required, get_jwt_identity

general_bp = Blueprint('general', __name__, url_prefix='/api')

@general_bp.route('/buscar', methods=['GET'])
@jwt_required()
def buscar():
    query = request.args.get('q', '').strip().lower()
    if not query:
        return jsonify({'error': 'Término de búsqueda vacío'}), 400

    user_id = get_jwt_identity()

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

        resultados_usuarios.append({
            'id': u.id,
            'username': u.username,
            'foto_perfil': u.foto_perfil,
            'relacion': seguimiento.tipo if seguimiento else None  # 'seguidor', 'amigo', o None
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



