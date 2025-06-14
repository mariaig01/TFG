import gevent.monkey
gevent.monkey.patch_all()

from flask import Flask
from config import DevelopmentConfig as Config
from extensions import socketio, db, jwt, mail
from routes.auth import auth_bp
from routes.posts import posts_bp
from routes.mensajes import mensajes_bp
from routes.groups import groups_bp
from routes.users import users_bp
from routes.general import general_bp
from routes.prendas import prendas_bp
from flask_cors import CORS


def create_app():
    app = Flask(__name__, static_folder='app/static')
    app.config.from_object(Config)
    CORS(app, supports_credentials=True)

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
    app.register_blueprint(prendas_bp)

    return app


app = create_app()

import socketio_handlers

if __name__ == '__main__':
    print("Ejecutando servidor Flask con soporte WebSocket (eventlet)")
    socketio.run(app, host='0.0.0.0', port=5000)
    #app.run(host='0.0.0.0', port=5000, debug=True)

