"""
Flask extensions initialization module.

This module initializes all Flask extensions used by the application without
creating circular imports.
"""
from flask_sqlalchemy import SQLAlchemy
from flask_migrate import Migrate
from flask_mail import Mail
from flask_login import LoginManager
from flask_jwt_extended import JWTManager
from flask_socketio import SocketIO
from flask_wtf import CSRFProtect
from flask_limiter import Limiter
from flask_limiter.util import get_remote_address
from flask_cors import CORS
from sqlalchemy import MetaData

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
login_manager = LoginManager()
jwt = JWTManager()
socketio = SocketIO(cors_allowed_origins="*", async_mode='gevent')
csrf = CSRFProtect()
# In app/extensions.py
from flask_limiter.util import get_remote_address
from flask_limiter import Limiter

#Configure limiter with Redis if available
try:
    from redis import Redis
    redis_client = Redis(host='localhost', port=6379, db=0)
    limiter = Limiter(
        get_remote_address,
        default_limits=["200 per day", "50 per hour"],
        storage_uri="redis://localhost:6379"
    )
except ImportError:
    # Fallback to memory storage with warning
    limiter = Limiter(
        get_remote_address,
        default_limits=["200 per day", "50 per hour"]
    )
cors = CORS()

try:
    from pymongo import MongoClient

    mongo_client = MongoClient("mongodb://localhost:27017/")
    mongo_db = mongo_client["looksy_db"]
    logs_collection = mongo_db["logs_actividad"]
except ImportError:
    mongo_client = None
    logs_collection = None