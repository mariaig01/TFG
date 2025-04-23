from flask import Blueprint, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from models import db, Favorito, Prenda
from datetime import datetime

prendas_bp = Blueprint('prendas', __name__, url_prefix='/prendas')

@prendas_bp.route('/<int:prenda_id>/guardar', methods=['POST'])
@jwt_required()
def guardar_prenda(prenda_id):
    user_id = int(get_jwt_identity())

    existente = Favorito.query.filter_by(id_usuario=user_id, id_prenda=prenda_id).first()
    if existente:
        return jsonify({'message': 'Ya está guardada'}), 200

    nueva = Favorito(id_usuario=user_id, id_prenda=prenda_id)
    db.session.add(nueva)
    db.session.commit()

    return jsonify({'message': 'Guardada correctamente'}), 201


@prendas_bp.route('/guardadas', methods=['GET'])
@jwt_required()
def obtener_prendas_guardadas():
    user_id = int(get_jwt_identity())

    favoritos = Favorito.query.filter_by(id_usuario=user_id).filter(Favorito.id_prenda != None).all()
    prendas_ids = [f.id_prenda for f in favoritos]

    prendas = Prenda.query.filter(Prenda.id.in_(prendas_ids)).order_by(Prenda.fecha_agregado.desc()).all()

    return jsonify([p.to_dict() for p in prendas]), 200
