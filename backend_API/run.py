from flask import Flask
from backend_API.config import BaseConfig as Config
from backend_API.config import DevelopmentConfig as Config

from backend_API.extensions import db
from backend_API.routes.auth import auth_bp
from backend_API.extensions import jwt
from backend_API.routes.posts import posts_bp
from backend_API.routes.mensajes import mensajes_bp
from backend_API.routes.groups import groups_bp
from backend_API.routes.users import users_bp
from backend_API.extensions import mail



def create_app():
    app = Flask(__name__, static_folder='app/static')
    app.config.from_object(Config)

    # Inicializa extensiones
    db.init_app(app)
    jwt.init_app(app)
    mail.init_app(app)

    # Registra blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(posts_bp)
    app.register_blueprint(mensajes_bp)
    app.register_blueprint(groups_bp)
    app.register_blueprint(users_bp)

    return app

# 👇 Esto es lo que Flask necesita para saber cuál es tu app
app = create_app()
