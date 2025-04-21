from flask import Flask
from backend_API.config import DevelopmentConfig as Config
from backend_API.extensions import socketio, db, jwt, mail
from backend_API.routes.auth import auth_bp
from backend_API.routes.posts import posts_bp
from backend_API.routes.mensajes import mensajes_bp
from backend_API.routes.groups import groups_bp
from backend_API.routes.users import users_bp
from backend_API.routes.general import general_bp


def create_app():
    app = Flask(__name__, static_folder='app/static')
    app.config.from_object(Config)

    # Inicializa extensiones
    db.init_app(app)
    jwt.init_app(app)
    mail.init_app(app)
    socketio.init_app(app)

    # Registra blueprints
    app.register_blueprint(auth_bp)
    app.register_blueprint(posts_bp)
    app.register_blueprint(mensajes_bp)
    app.register_blueprint(groups_bp)
    app.register_blueprint(users_bp)
    app.register_blueprint(general_bp)

    return app


app = create_app()

# Importa handlers para registrar los eventos socket
from backend_API import socketio_handlers

if __name__ == '__main__':
    print("🚀 Ejecutando servidor Flask con soporte WebSocket (eventlet)")
    socketio.run(app, host='0.0.0.0', port=5000)
