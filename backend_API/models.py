from flask_login import UserMixin
from sqlalchemy.sql import func
from backend_API.extensions import db
from datetime import datetime



class User(db.Model, UserMixin):
    __tablename__ = 'usuarios'  # nombre exacto de la tabla en PostgreSQL

    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(50), unique=True, nullable=False)
    nombre = db.Column(db.String(50), nullable=True)
    apellido = db.Column(db.String(50), nullable=True)
    email = db.Column(db.String(100), unique=True, nullable=False)
    contraseña = db.Column(db.String(255), nullable=False)
    fecha_registro = db.Column(db.DateTime(timezone=True), default=func.now())
    foto_perfil = db.Column(db.String(255), nullable=True)
    bio = db.Column(db.Text, default="")
    verificado = db.Column(db.Boolean, default=False)
    rol = db.Column(db.String(20), nullable=True)
    token = db.Column(db.String(255), unique=True, nullable=True)
    reset_token = db.Column(db.String(255), unique=True, nullable=True)
    reset_token_expiration = db.Column(db.DateTime(timezone=True), nullable=True)
    fecha_modificacion = db.Column(db.DateTime(timezone=True), default=func.now(), onupdate=func.now())

    def __repr__(self):
        return f"<Usuario {self.id}: {self.email}>"

    def get_id(self):
        return str(self.id)

    @property
    def is_active(self):
        return True  # o puedes usar `self.verificado`

    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        return False

    def to_dict(self):
        return {
            'id': self.id,
            'username': self.username,
            'nombre': self.nombre,
            'apellido': self.apellido,
            'email': self.email,
            'bio': self.bio,
            'foto_perfil': self.foto_perfil,
            'verificado': self.verificado,
            'rol': self.rol,
            'fecha_registro': self.fecha_registro.isoformat() if self.fecha_registro else None,
            'fecha_modificacion': self.fecha_modificacion.isoformat() if self.fecha_modificacion else None
        }

    def set_password(self, raw_password):
        from werkzeug.security import generate_password_hash
        self.contraseña = generate_password_hash(raw_password)

    def check_password(self, password):
        from werkzeug.security import check_password_hash
        return check_password_hash(self.contraseña, password)

class Post(db.Model):
    __tablename__ = 'publicaciones'

    id = db.Column(db.Integer, primary_key=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    contenido = db.Column(db.Text, nullable=False)
    imagen_url = db.Column(db.String(255), nullable=False)
    fecha_publicacion = db.Column(db.DateTime(timezone=True), default=func.now())
    visibilidad = db.Column(db.String(20), nullable=False, default='publico')

    usuario = db.relationship('User', backref='publicaciones')

    # 👉 Relación con los likes
    likes = db.relationship('Like', backref='post', cascade='all, delete-orphan')


class Seguimiento(db.Model):
    __tablename__ = 'seguimientos'

    id = db.Column(db.Integer, primary_key=True)
    id_seguidor = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    id_seguido = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tipo = db.Column(db.String(20))  # 'seguidor' o 'amigo'
    estado = db.Column(db.String(20))  # 'pendiente' o 'aceptada'

    # Relaciones opcionales
    seguidor = db.relationship('User', foreign_keys=[id_seguidor], backref='seguidos')
    seguido = db.relationship('User', foreign_keys=[id_seguido], backref='seguidores')


class Comentario(db.Model):
    __tablename__ = 'comentarios'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_publicacion = db.Column(db.Integer, db.ForeignKey('publicaciones.id', ondelete="CASCADE"), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete="CASCADE"), nullable=False)
    texto = db.Column(db.Text, nullable=False)
    fecha_comentario = db.Column(db.DateTime, default=datetime.utcnow)

    usuario = db.relationship('User', backref='comentarios')
    publicacion = db.relationship('Post', backref='comentarios')


class Like(db.Model):
    __tablename__ = 'likes'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_publicacion = db.Column(db.Integer, db.ForeignKey('publicaciones.id', ondelete="CASCADE"), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete="CASCADE"), nullable=False)
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)

    usuario = db.relationship('User', backref='likes')

    __table_args__ = (
        db.UniqueConstraint('id_usuario', 'id_publicacion', name='unique_like'),
    )

class Mensaje(db.Model):
    __tablename__ = 'mensajes'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_emisor = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    id_receptor = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    mensaje = db.Column(db.Text, nullable=True)
    id_publicacion = db.Column(db.Integer, db.ForeignKey('publicaciones.id'), nullable=True)
    fecha_envio = db.Column(db.DateTime, default=datetime.utcnow)
    estado = db.Column(db.String(20), default='pendiente')

    # Relaciones opcionales
    emisor = db.relationship('User', foreign_keys=[id_emisor], backref='mensajes_enviados')
    receptor = db.relationship('User', foreign_keys=[id_receptor], backref='mensajes_recibidos')
    publicacion = db.relationship('Post', backref='mensajes')