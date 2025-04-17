from flask import Blueprint, request, jsonify
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import (
    create_access_token,
    create_refresh_token,
    jwt_required,
    get_jwt_identity,
    decode_token
)
from flask_mail import Message
from datetime import timedelta
from backend_API.models import User
from backend_API.extensions import db, mail
from backend_API.utils.helpers import is_strong_password

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')


# Enviar email con enlace que abre la app Flutter
def enviar_email_verificacion(usuario):
    token = create_access_token(identity=str(usuario.id), expires_delta=timedelta(hours=24))

    # Enlace deep link que tu app Flutter debe manejar
    enlace = f"looksy://verify?token={token}"

    mensaje = Message(
        subject="Verifica tu cuenta",
        recipients=[usuario.email],
        body=(
            f"Hola {usuario.nombre},\n\n"
            f"Gracias por registrarte en Looksy.\n\n"
            f"Pulsa el siguiente enlace para verificar tu cuenta y acceder a la aplicación:\n\n"
            f"{enlace}\n\n"
            f"Este enlace expirará en 24 horas.\n\n"
            f"Si no te has registrado, ignora este correo."
        )
    )
    mail.send(mensaje)


# Registro
@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    email = data.get('email')
    username = data.get('username')
    nombre = data.get('nombre')
    apellido = data.get('apellido')
    password = data.get('password')
    bio = data.get('bio')
    rol = data.get('rol')

    # Validación de campos obligatorios
    if not username or not email or not nombre or not password:
        return jsonify({"error": "Faltan campos obligatorios"}), 400

    # Buscar usuario existente por email
    existing_user = User.query.filter_by(email=email).first()
    if existing_user:
        if existing_user.verificado:
            return jsonify({"error": "El email ya está registrado"}), 400
        else:
            # ⚠️ Usuario no verificado → lo borramos para permitir registro nuevo
            db.session.delete(existing_user)
            db.session.commit()

    # También puedes hacer lo mismo con el username si quieres:
    if User.query.filter_by(username=username).first():
        return jsonify({"error": "El nombre de usuario ya está en uso"}), 400

    if not is_strong_password(password):
        return jsonify({"error": "La contraseña no es suficientemente fuerte"}), 400

    nuevo_usuario = User(
        username=username,
        email=email,
        nombre=nombre,
        apellido=apellido,
        contraseña=generate_password_hash(password),
        bio=bio,
        rol=rol,
        verificado=False
    )

    db.session.add(nuevo_usuario)
    db.session.commit()

    enviar_email_verificacion(nuevo_usuario)

    return jsonify({"message": "Usuario creado con éxito. Verifica tu correo."}), 201



# Ruta que llamará la app Flutter para verificar email
@auth_bp.route('/verify-email-mobile', methods=['POST'])
def verify_email_mobile():
    data = request.get_json()
    token = data.get('token')

    if not token:
        return jsonify({'error': 'Token no recibido'}), 400

    try:
        decoded_token = decode_token(token)
        user_id = decoded_token.get('sub')
        user = User.query.get(int(user_id))

        if not user:
            return jsonify({'error': 'Usuario no encontrado'}), 404

        if user.verificado:
            return jsonify({'message': 'Cuenta ya verificada'}), 200

        user.verificado = True
        db.session.commit()
        return jsonify({'message': 'Cuenta verificada correctamente'}), 200

    except Exception as e:
        return jsonify({'error': f'Token inválido o expirado: {str(e)}'}), 400


# Login
@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"error": "Email y contraseña obligatorios"}), 400

    user = User.query.filter_by(email=email).first()

    if not user or not check_password_hash(user.contraseña, password):
        return jsonify({"error": "Credenciales inválidas"}), 401

    if not user.verificado:
        return jsonify({"error": "Tu cuenta no ha sido verificada. Revisa tu correo."}), 403

    access_token = create_access_token(identity=str(user.id))
    refresh_token = create_refresh_token(identity=str(user.id))

    return jsonify({
        "message": "Login exitoso",
        "access_token": access_token,
        "refresh_token": refresh_token
    }), 200


# Refrescar token
@auth_bp.route('/refresh', methods=['POST'])
@jwt_required(refresh=True)
def refresh_token():
    identity = get_jwt_identity()
    new_access_token = create_access_token(identity=identity)
    return jsonify(access_token=new_access_token), 200


@auth_bp.route('/reset-password', methods=['POST'])
def reset_password():
    data = request.get_json()
    token = data.get('token')
    new_password = data.get('password')

    if not token or not new_password:
        return jsonify({"error": "Token y contraseña son obligatorios"}), 400

    # Buscar el usuario con ese token
    user = User.query.filter_by(reset_token=token).first()

    if not user:
        return jsonify({"error": "Token inválido"}), 404

    if user.reset_token_expiration is None or user.reset_token_expiration < datetime.utcnow():
        return jsonify({"error": "El token ha expirado"}), 400

    if len(new_password) < 7:
        return jsonify({"error": "La contraseña debe tener al menos 7 caracteres"}), 400

    # Hashear y guardar la nueva contraseña
    user.contraseña = generate_password_hash(new_password)
    user.reset_token = None
    user.reset_token_expiration = None
    db.session.commit()

    return jsonify({"message": "Contraseña actualizada. Ya puedes iniciar sesión."}), 200