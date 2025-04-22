from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_mail import Mail
from flask_jwt_extended import JWTManager
from flask_socketio import SocketIO
from sqlalchemy import MetaData
import os

# Create extension instances
naming_convention = {
    "ix": "ix_%(table_name)s_%(column_0_label)s",
    "uq": "uq_%(table_name)s_%(column_0_name)s",
    "ck": "ck_%(table_name)s_%(constraint_name)s",
    "fk": "fk_%(table_name)s_%(column_0_name)s_%(referred_table_name)s",
    "pk": "pk_%(table_name)s"
}

metadata = MetaData(naming_convention=naming_convention)
db = SQLAlchemy(metadata=metadata)

migrate = Migrate()
mail = Mail()
jwt = JWTManager()
socketio = SocketIO(cors_allowed_origins="*", async_mode='gevent')

# Limiter (con Redis si está disponible y configurado)
from flask_limiter.util import get_remote_address
from flask_limiter import Limiter

try:
    from redis import Redis
    redis_url = os.environ.get("REDIS_URL", "redis://localhost:6379")
    redis_client = Redis.from_url(redis_url)
    limiter = Limiter(
        get_remote_address,
        default_limits=["200 per day", "50 per hour"],
        storage_uri=redis_url
    )
except ImportError:
    redis_client = None
    limiter = Limiter(
        get_remote_address,
        default_limits=["200 per day", "50 per hour"]
    )

# MongoDB para logs de actividad
try:
    from pymongo import MongoClient
    mongo_uri = os.environ.get("MONGO_URI", "mongodb://localhost:27017/")
    mongo_client = MongoClient(mongo_uri)
    mongo_db = mongo_client["looksy_db"]
    logs_collection = mongo_db["logs_actividad"]
except ImportError:
    mongo_client = None
    logs_collection = None
