from flask import Blueprint, request, jsonify
from flask_login import login_user, logout_user, current_user, login_required
from werkzeug.security import generate_password_hash
from backend_API.models import User
from backend_API.extensions import db
from backend_API.utils.helpers import is_strong_password
from werkzeug.security import generate_password_hash, check_password_hash
from flask_jwt_extended import create_access_token, get_jwt_identity, jwt_required

auth_bp = Blueprint('auth', __name__, url_prefix='/auth')

@auth_bp.route('/register', methods=['POST'])
def register():
    data = request.get_json()

    username = data.get('username')
    email = data.get('email')
    nombre = data.get('nombre')
    apellido = data.get('apellido')
    password = data.get('password')  # lo recibes como "password" desde el JSON
    bio = data.get('bio')
    rol = data.get('rol')

    # Validación de campos obligatorios
    if not username or not email or not nombre or not password:
        return jsonify({"error": "Todos los campos obligatorios deben estar completos (username, email, nombre, contraseña)"}), 400

    # Validar duplicidad de email y username
    if User.query.filter_by(email=email).first():
        return jsonify({"error": "El email ya está registrado"}), 400

    if User.query.filter_by(username=username).first():
        return jsonify({"error": "El nombre de usuario ya está en uso"}), 400

    # Validación de fortaleza de la contraseña
    if not is_strong_password(password):
        return jsonify({"error": "La contraseña no es suficientemente fuerte"}), 400

    # Crear nuevo usuario
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

    return jsonify({"message": "Usuario creado con éxito"}), 201

@auth_bp.route('/login', methods=['POST'])
def login():
    data = request.get_json()

    email = data.get('email')
    password = data.get('password')

    if not email or not password:
        return jsonify({"error": "Email y contraseña son obligatorios"}), 400

    user = User.query.filter_by(email=email).first()

    if user and check_password_hash(user.contraseña, password):
        access_token = create_access_token(identity=str(user.id))

        return jsonify(access_token=access_token), 200
    else:
        return jsonify({"error": "Credenciales inválidas"}), 401