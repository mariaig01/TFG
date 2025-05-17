from flask import Blueprint, request, jsonify, current_app
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, User, Grupo, GrupoUsuario, Seguimiento, Prenda
import requests
from fastapi import UploadFile, File
import os
import shutil


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




@general_bp.route('/search-prendas', methods=['GET'])
def search_prendas():
    query = request.args.get('q')
    if not query:
        return jsonify([])

    try:
        import os
        api_key = os.getenv('SERPAPI_KEY')

        params = {
            "engine": "google",
            "q": query,
            "tbm": "shop",
            "api_key": api_key,
            "num": 30,
            "async": "true"
        }

        response = requests.get(
            "https://serpapi.com/search",
            params=params,
            timeout=10  # previene cuelgues
        )
        response.raise_for_status()
        data = response.json()

        productos = data.get("shopping_results", [])

        prendas = [{
            "store": p.get("source", "Tienda"),
            "product": p.get("title", "Producto"),
            "price": p.get("price", "0 €"),
            "imagen": p.get("thumbnail", ""),
            "link": p.get("link") or p.get("product_link", "")
        } for p in productos if p.get("link") or p.get("product_link")]

        return jsonify(prendas)

    except Exception as e:
        print(f"Error en búsqueda SerpApi: {e}")
        return jsonify([]), 500




@general_bp.route('/costos/total', methods=['GET'])
@jwt_required()
def obtener_costo_total():
    user_id = get_jwt_identity()
    total = db.session.query(db.func.sum(Prenda.precio)).filter(Prenda.id_usuario == user_id)\
        .scalar()
    return jsonify({"total": float(total) if total else 0.0})

@general_bp.route('/costos/por-tipo', methods=['GET'])
@jwt_required()
def obtener_costo_por_tipo():
    user_id = get_jwt_identity()
    resultados = db.session.query(
        Prenda.tipo, db.func.sum(Prenda.precio)
    ).filter(
        Prenda.id_usuario == user_id
    ).group_by(
        Prenda.tipo
    ).all()

    response = {tipo.value: float(total) for tipo, total in resultados if total is not None}
    return jsonify(response)


@general_bp.route('/costos/evolucion', methods=['GET'])
@jwt_required()
def obtener_evolucion_gastos_diaria():
    user_id = get_jwt_identity()
    resultados = db.session.query(
        db.func.to_char(Prenda.fecha_agregado, 'YYYY-MM-DD'),
        db.func.sum(Prenda.precio)
    ).filter(
        Prenda.id_usuario == user_id
    ).group_by(
        db.func.to_char(Prenda.fecha_agregado, 'YYYY-MM-DD')
    ).order_by(
        db.func.to_char(Prenda.fecha_agregado, 'YYYY-MM-DD')
    ).all()

    return jsonify([
        {"dia": dia, "total": float(total)} for dia, total in resultados if total is not None
    ])

