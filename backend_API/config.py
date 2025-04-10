"""
Application configuration module.

This module defines configuration classes for different environments.
"""
import os
from datetime import timedelta
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()


class BaseConfig:
    """Base configuration class with common settings."""

    # Secret key for session management and CSRF protection
    SECRET_KEY = os.getenv("SECRET_KEY")

    # Flask-SQLAlchemy settings
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT settings
    JWT_SECRET_KEY = os.getenv("JWT_SECRET_KEY", SECRET_KEY)
    JWT_TOKEN_LOCATION = ['headers']
    JWT_ACCESS_TOKEN_EXPIRES = timedelta(hours=1)

    # Upload paths
    UPLOAD_FOLDER = os.path.join(os.getcwd(), 'app', 'static', 'uploads')
    PROFILE_IMAGE_FOLDER = os.path.join(os.getcwd(), 'app', 'static', 'profile_images')
    TEMP_UPLOAD_FOLDER = os.path.join(os.getcwd(), 'app', 'static', 'temp_uploads')

    # Create upload directories if they don't exist
    for folder in [UPLOAD_FOLDER, PROFILE_IMAGE_FOLDER, TEMP_UPLOAD_FOLDER]:
        os.makedirs(folder, exist_ok=True)

    # Flask-Mail settings
    MAIL_SERVER = os.getenv("MAIL_SERVER", "smtp.gmail.com")
    MAIL_PORT = int(os.getenv("MAIL_PORT", 587))
    MAIL_USE_TLS = os.getenv("MAIL_USE_TLS", "true").lower() in ["true", "1"]
    MAIL_USERNAME = os.getenv("MAIL_USERNAME")
    MAIL_PASSWORD = os.getenv("MAIL_PASSWORD")
    MAIL_DEFAULT_SENDER = os.getenv("MAIL_DEFAULT_SENDER")

    # Session and cookie settings for security
    SESSION_COOKIE_SECURE = True
    REMEMBER_COOKIE_SECURE = True
    SESSION_COOKIE_HTTPONLY = True
    REMEMBER_COOKIE_HTTPONLY = True
    SESSION_COOKIE_SAMESITE = 'Lax'

    # CORS settings
    CORS_ORIGINS = ["http://localhost:3000", "https://looksy.app"]

    # File upload settings
    MAX_CONTENT_LENGTH = 5 * 1024 * 1024  # 5 MB max upload size
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif'}


class DevelopmentConfig(BaseConfig):
    """Development environment configuration."""

    DEBUG = True
    TESTING = False

    # Override cookie security settings for development
    SESSION_COOKIE_SECURE = False
    REMEMBER_COOKIE_SECURE = False

    # Development database
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")

    # Development-specific settings
    CORS_ORIGINS = ["*"]  # Allow all origins in development


class TestingConfig(BaseConfig):
    """Testing environment configuration."""

    DEBUG = False
    TESTING = True

    # Use in-memory database for testing
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")

    # Test-specific settings
    WTF_CSRF_ENABLED = False
    PRESERVE_CONTEXT_ON_EXCEPTION = False


class ProductionConfig(BaseConfig):
    """Production environment configuration."""

    DEBUG = False
    TESTING = False

    # Use PostgreSQL in production
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL")

    # Add production-specific security headers
    SECURE_HEADERS = {
        'X-Frame-Options': 'SAMEORIGIN',
        'X-XSS-Protection': '1; mode=block',
        'X-Content-Type-Options': 'nosniff',
        'Strict-Transport-Security': 'max-age=31536000; includeSubDomains',
        'Content-Security-Policy': "default-src 'self'; script-src 'self' 'unsafe-inline' cdn.jsdelivr.net code.jquery.com cdnjs.cloudflare.com; style-src 'self' 'unsafe-inline' stackpath.bootstrapcdn.com cdn.jsdelivr.net; img-src 'self' data:; font-src 'self' stackpath.bootstrapcdn.com; connect-src 'self'"
    }

    # Use stronger password hashing in production
    SECURITY_PASSWORD_HASH = os.getenv("SECURITY_PASSWORD_HASH")
    SECURITY_PASSWORD_SALT = os.getenv("SECURITY_PASSWORD_SALT")

    # Error emails
    ADMINS = [x.strip() for x in os.getenv("ADMINS", "").split(",")]

    # Logging
    LOG_TO_STDOUT = os.getenv("LOG_TO_STDOUT", "false").lower() in ["true", "1"]