import os
import uuid
from flask import Blueprint, request, jsonify, current_app, send_from_directory
from flask_jwt_extended import jwt_required, get_jwt_identity
from werkzeug.utils import secure_filename
from extensions import db, logs_collection
from models import Prenda, User, SolicitudPrenda
from datetime import datetime
from utils.image_processing import remove_background_and_white_bg

prendas_bp = Blueprint('prendas', __name__, url_prefix='/prendas')

@prendas_bp.route('/api/create', methods=['POST'])
@jwt_required()
def crear_prenda():
    usuario_id = int(get_jwt_identity())

    nombre = request.form.get('nombre', '').strip()
    descripcion = request.form.get('descripcion', '').strip()
    precio = request.form.get('precio')
    talla = request.form.get('talla', '').strip()
    color = request.form.get('color', '').strip()
    solicitable = request.form.get('solicitable') == 'true'
    imagen_file = request.files.get('imagen')
    eliminar_fondo = request.form.get('eliminar_fondo', 'true').lower() == 'true'

    if not nombre or not precio or not imagen_file:
        return jsonify({'error': 'Nombre, precio e imagen son obligatorios'}), 400

    ext = imagen_file.filename.rsplit('.', 1)[-1].lower()
    if ext not in ['jpg', 'jpeg', 'png']:
        return jsonify({'error': 'Extensión de imagen no válida'}), 400

    try:
        nombre_seguro = secure_filename(imagen_file.filename)
        nombre_final = f"{uuid.uuid4().hex}.{ext}"

        temp_path = os.path.join(current_app.root_path, 'static', 'temp_uploads', nombre_final)
        final_path = os.path.join(current_app.root_path, 'static', 'prendas_images', nombre_final)

        os.makedirs(os.path.dirname(temp_path), exist_ok=True)
        os.makedirs(os.path.dirname(final_path), exist_ok=True)

        imagen_file.save(temp_path)
        remove_background_and_white_bg(temp_path, final_path, eliminar_fondo=eliminar_fondo)
        os.remove(temp_path)

        imagen_url = f"/prendas/uploads/{nombre_final}"


    except Exception as e:
        return jsonify({'error': f'Error al procesar imagen: {str(e)}'}), 500

    nueva_prenda = Prenda(
        id_usuario=usuario_id,
        nombre=nombre,
        descripcion=descripcion,
        precio=precio,
        talla=talla,
        color=color,
        imagen_url=imagen_url,
        fecha_agregado=datetime.utcnow(),
        fecha_modificacion=datetime.utcnow(),
        solicitable=solicitable
    )

    db.session.add(nueva_prenda)
    db.session.commit()

    if logs_collection is not None:
        logs_collection.insert_one({
            "evento": "prenda_creada",
            "usuario_id": usuario_id,
            "nombre": nombre,
            "precio": precio,
            "imagen_url": imagen_url,
            "timestamp": datetime.utcnow()
        })

    return jsonify({'message': 'Prenda creada con éxito'}), 201

@prendas_bp.route('/uploads/<filename>')
def serve_uploaded_prenda(filename):
    uploads_dir = os.path.join(current_app.root_path, 'static', 'prendas_images')
    return send_from_directory(uploads_dir, filename)


@prendas_bp.route('/api/mis-prendas', methods=['GET'])
@jwt_required()
def obtener_mis_prendas():
    usuario_id = int(get_jwt_identity())

    prendas = Prenda.query.filter_by(id_usuario=usuario_id).order_by(Prenda.fecha_agregado.desc()).all()

    return jsonify([
        {
            'id': p.id,
            'nombre': p.nombre,
            'descripcion': p.descripcion,
            'precio': float(p.precio),
            'talla': p.talla,
            'color': p.color,
            'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
            'solicitable': p.solicitable,
            'fecha_agregado': p.fecha_agregado.isoformat()
        } for p in prendas
    ]), 200

@prendas_bp.route('/api/<int:prenda_id>/editar', methods=['PUT'])
@jwt_required()
def editar_prenda(prenda_id):
    usuario_id = int(get_jwt_identity())
    prenda = Prenda.query.filter_by(id=prenda_id, id_usuario=usuario_id).first()

    if not prenda:
        return jsonify({'error': 'Prenda no encontrada o no autorizada'}), 404

    data = request.get_json()
    prenda.nombre = data.get('nombre', prenda.nombre)
    prenda.descripcion = data.get('descripcion', prenda.descripcion)
    prenda.precio = data.get('precio', prenda.precio)
    prenda.talla = data.get('talla', prenda.talla)
    prenda.color = data.get('color', prenda.color)
    prenda.fecha_modificacion = datetime.utcnow()

    db.session.commit()

    return jsonify({'message': 'Prenda actualizada con éxito'}), 200


@prendas_bp.route('/api/<int:prenda_id>/eliminar', methods=['DELETE'])
@jwt_required()
def eliminar_prenda(prenda_id):
    usuario_id = int(get_jwt_identity())
    prenda = Prenda.query.filter_by(id=prenda_id, id_usuario=usuario_id).first()

    if not prenda:
        return jsonify({'error': 'Prenda no encontrada o no autorizada'}), 404

    # Ruta del archivo en disco
    if prenda.imagen_url:
        try:
            nombre_archivo = prenda.imagen_url.split("/")[-1]
            ruta_imagen = os.path.join(current_app.root_path, 'static', 'prendas_images', nombre_archivo)
            if os.path.exists(ruta_imagen):
                os.remove(ruta_imagen)
        except Exception as e:
            print(f"⚠️ Error al eliminar imagen física: {e}")

    db.session.delete(prenda)
    db.session.commit()

    return jsonify({'message': 'Prenda eliminada correctamente'}), 200

@prendas_bp.route('/usuario/<int:user_id>', methods=['GET'])
@jwt_required()
def obtener_prendas_usuario(user_id):
    usuario = User.query.get(user_id)
    if not usuario:
        return jsonify({'error': 'Usuario no encontrado'}), 404

    prendas = Prenda.query.filter_by(id_usuario=user_id).order_by(Prenda.fecha_agregado.desc()).all()

    return jsonify([{
        'id': p.id,
        'nombre': p.nombre,
        'descripcion': p.descripcion,
        'precio': float(p.precio),
        'talla': p.talla,
        'color': p.color,
        'imagen_url': f"{current_app.config['BASE_URL']}{p.imagen_url}" if p.imagen_url else None,
        'solicitable': p.solicitable,
        'fecha_agregado': p.fecha_agregado.isoformat()
    } for p in prendas]), 200


@prendas_bp.route('/<int:prenda_id>/solicitar', methods=['POST'])
@jwt_required()
def solicitar_prenda(prenda_id):
    usuario_id = int(get_jwt_identity())
    prenda = Prenda.query.get(prenda_id)

    if not prenda:
        return jsonify({'error': 'Prenda no encontrada'}), 404

    if prenda.id_usuario == usuario_id:
        return jsonify({'error': 'No puedes solicitar tu propia prenda'}), 400

    # Evitar duplicados
    existente = SolicitudPrenda.query.filter_by(
        id_prenda=prenda_id,
        id_remitente=usuario_id,
        id_destinatario=prenda.id_usuario,
        estado='pendiente'
    ).first()

    if existente:
        return jsonify({'error': 'Ya has solicitado esta prenda'}), 409

    solicitud = SolicitudPrenda(
        id_prenda=prenda_id,
        id_remitente=usuario_id,
        id_destinatario=prenda.id_usuario,
        estado='pendiente'
    )

    db.session.add(solicitud)
    db.session.commit()

    return jsonify({'message': 'Solicitud de prenda registrada'}), 201



@prendas_bp.route('/solicitudes/<int:solicitud_id>/aceptar', methods=['POST'])
@jwt_required()
def aceptar_solicitud_prenda(solicitud_id):
    usuario_id = int(get_jwt_identity())

    solicitud = SolicitudPrenda.query.filter_by(
        id=solicitud_id,
        id_destinatario=usuario_id,
        estado='pendiente'
    ).first()

    if not solicitud:
        return jsonify({"error": "Solicitud no encontrada o no autorizada"}), 404

    solicitud.estado = 'aceptada'
    db.session.commit()

    return jsonify({"message": "Solicitud de prenda aceptada"}), 200



@prendas_bp.route('/solicitudes/<int:solicitud_id>/rechazar', methods=['POST'])
@jwt_required()
def rechazar_solicitud_prenda(solicitud_id):
    usuario_id = int(get_jwt_identity())

    solicitud = SolicitudPrenda.query.filter_by(
        id=solicitud_id,
        id_destinatario=usuario_id,
        estado='pendiente'
    ).first()

    if not solicitud:
        return jsonify({"error": "Solicitud no encontrada o no autorizada"}), 404

    solicitud.estado = 'rechazada'
    db.session.commit()

    return jsonify({"message": "Solicitud de prenda rechazada"}), 200

