from flask_login import UserMixin
from sqlalchemy.sql import func
from extensions import db
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

    #Relación con los likes
    likes = db.relationship('Like', backref='post', cascade='all, delete-orphan')

    def to_dict(self):
        return {
            "id": self.id,
            "contenido": self.contenido,
            "imagen_url": f"http://192.168.1.43:5000{self.imagen_url}" if self.imagen_url else None,
            "usuario": self.usuario.username
        }

class Grupo(db.Model):
    __tablename__ = 'grupos'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nombre = db.Column(db.String(100), nullable=False)
    descripcion = db.Column(db.Text, nullable=True)
    creador = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='SET NULL'))
    fecha_creacion = db.Column(db.DateTime, default=datetime.utcnow)
    imagen = db.Column(db.String(255), nullable=True)

    miembros = db.relationship('GrupoUsuario', back_populates='grupo', cascade="all, delete-orphan")
    mensajes = db.relationship('MensajeGrupo', back_populates='grupo', cascade="all, delete-orphan")


    def to_dict(self):
        return {
            'id': self.id,
            'nombre': self.nombre,
            'descripcion': self.descripcion,
            'creador': self.creador,
            'fecha_creacion': self.fecha_creacion.isoformat() if self.fecha_creacion else None,
            'imagen': self.imagen
        }

class GrupoUsuario(db.Model):
    __tablename__ = 'grupo_usuarios'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_grupo = db.Column(db.Integer, db.ForeignKey('grupos.id', ondelete='CASCADE'), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    rol = db.Column(db.String(20), default='miembro')
    fecha_ingreso = db.Column(db.DateTime, default=datetime.utcnow)

    grupo = db.relationship('Grupo', back_populates='miembros')
    usuario = db.relationship('User', backref=db.backref('grupos', lazy='dynamic', cascade='all, delete-orphan'))

    def to_dict(self):
        return {
            'id': self.id,
            'id_grupo': self.id_grupo,
            'id_usuario': self.id_usuario,
            'rol': self.rol,
            'fecha_ingreso': self.fecha_ingreso.isoformat()
        }


class Seguimiento(db.Model):
    __tablename__ = 'seguimientos'

    id = db.Column(db.Integer, primary_key=True)
    id_seguidor = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    id_seguido = db.Column(db.Integer, db.ForeignKey('usuarios.id'), nullable=False)
    tipo = db.Column(db.String(20))  # 'seguidor' o 'amigo'
    estado = db.Column(db.String(20), default='pendiente')
    fecha_inicio = db.Column(db.DateTime, default=datetime.utcnow)

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

    def to_dict(self):
        return {
            "id": self.id,
            "id_emisor": self.id_emisor,
            "id_receptor": self.id_receptor,
            "mensaje": self.mensaje,
            "id_publicacion": self.id_publicacion,
            "fecha_envio": self.fecha_envio.isoformat() if self.fecha_envio else None,
            "publicacion": self.publicacion.to_dict() if self.publicacion else None

        }


class MensajeGrupo(db.Model):
    __tablename__ = 'mensajes_grupo'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_grupo = db.Column(db.Integer, db.ForeignKey('grupos.id', ondelete='CASCADE'), nullable=False)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    id_publicacion = db.Column(db.Integer, db.ForeignKey('publicaciones.id', ondelete='SET NULL'), nullable=True)
    mensaje = db.Column(db.Text, nullable=False)
    fecha_envio = db.Column(db.DateTime, default=datetime.utcnow)

    grupo = db.relationship('Grupo', back_populates='mensajes')
    usuario = db.relationship('User', backref='mensajes_grupo')
    publicacion = db.relationship('Post')

    def to_dict(self):
        return {
            'id': self.id,
            'id_grupo': self.id_grupo,
            'id_usuario': self.id_usuario,
            'mensaje': self.mensaje,
            'fecha_envio': self.fecha_envio.isoformat(),
            'autor': self.usuario.username if self.usuario else "Anónimo",
            'publicacion': self.publicacion.to_dict() if self.publicacion else None
        }


class Favorito(db.Model):
    __tablename__ = 'favoritos'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    id_prenda = db.Column(db.Integer, db.ForeignKey('prendas.id'), nullable=True)
    id_publicacion = db.Column(db.Integer, db.ForeignKey('publicaciones.id'), nullable=True)
    fecha_agregado = db.Column(db.DateTime, default=datetime.utcnow)

    usuario = db.relationship('User', backref='favoritos')
    publicacion = db.relationship('Post', foreign_keys=[id_publicacion], backref='favoritos')
    prenda = db.relationship('Prenda', foreign_keys=[id_prenda], backref='favoritos')


class Prenda(db.Model):
    __tablename__ = 'prendas'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    id_usuario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'), nullable=False)
    nombre = db.Column(db.String(100), nullable=False)
    descripcion = db.Column(db.Text)
    precio = db.Column(db.Numeric(10, 2))
    talla = db.Column(db.String(10))
    color = db.Column(db.String(30))
    imagen_url = db.Column(db.String(255))
    fecha_agregado = db.Column(db.DateTime, default=datetime.utcnow)
    fecha_modificacion = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    solicitable = db.Column(db.Boolean, default=False)
    tipo = db.Column(db.Enum(
        'Camisa', 'Camiseta', 'Blusa', 'Top', 'Vestido', 'Falda', 'Pantalón',
        'Vaqueros', 'Shorts', 'Sudadera', 'Jersey', 'Rebeca', 'Corset',
        'Chaqueta', 'Abrigo', 'Blazer', 'Chaleco', 'Cárdigan', 'Mono', 'Traje',
        'Chándal', 'Mallas', 'Bikini', 'Polo', 'Zapato', 'Bota', 'Sandalia',
        'Tacón', 'Zapatilla deportiva', 'Cinturón', 'Bufanda', 'Pañuelo',
        'Medias', 'Gorro', 'Sombrero', 'Guantes', 'Bolso', 'Mochila',
        'Reloj', 'Pulsera', 'Collar', 'Pendientes', 'Gafas de sol', 'Otro',
        name='tipo_prenda_enum'
    ), nullable=False, default='Otro')
    emocion = db.Column(db.Enum(
        'feliz', 'triste', 'enfadado', 'sorprendido', 'miedo', 'asco', 'neutro',
        name='emocion_enum'
    ), nullable=True)

    usuario = db.relationship('User', backref='prendas')

    def to_dict(self):
        return {
            'id': self.id,
            'id_usuario': self.id_usuario,
            'nombre': self.nombre,
            'descripcion': self.descripcion,
            'precio': float(self.precio) if self.precio else None,
            'talla': self.talla,
            'color': self.color,
            'imagen_url': self.imagen_url,
            'fecha_agregado': self.fecha_agregado.isoformat() if self.fecha_agregado else None,
            'fecha_modificacion': self.fecha_modificacion.isoformat() if self.fecha_modificacion else None,
            'solicitable': self.solicitable,
            'tipo': self.tipo,
            'emocion': self.emocion

        }




class Categoria(db.Model):
    __tablename__ = 'categorias'

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    nombre = db.Column(db.String(100), unique=True, nullable=False, index=True)

    def __repr__(self):
        return f"<Categoria {self.id}: {self.nombre}>"


class PrendaCategoria(db.Model):
    __tablename__ = 'prendas_categorias'

    prenda_id = db.Column(db.Integer, db.ForeignKey('prendas.id', ondelete='CASCADE'), primary_key=True)
    categoria_id = db.Column(db.Integer, db.ForeignKey('categorias.id', ondelete='CASCADE'), primary_key=True)
    estacion = db.Column(db.Enum('Primavera', 'Verano', 'Otoño', 'Invierno', 'Cualquiera', name='estacion_enum'), nullable=False)

    # Relaciones (opcional, pero recomendable para hacer joins más fáciles)
    prenda = db.relationship('Prenda', backref=db.backref('prendas_categorias', cascade='all, delete-orphan'))
    categoria = db.relationship('Categoria', backref=db.backref('prendas_categorias', cascade='all, delete-orphan'))

    def __repr__(self):
        return f"<PrendaCategoria prenda_id={self.prenda_id}, categoria_id={self.categoria_id}, estacion={self.estacion}>"



class SolicitudPrenda(db.Model):
    __tablename__ = 'solicitudes_prenda'

    id = db.Column(db.Integer, primary_key=True)
    id_prenda = db.Column(db.Integer, db.ForeignKey('prendas.id', ondelete='CASCADE'))
    id_remitente = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'))
    id_destinatario = db.Column(db.Integer, db.ForeignKey('usuarios.id', ondelete='CASCADE'))
    estado = db.Column(db.String(20), default='pendiente')
    fecha_solicitud = db.Column(db.DateTime, default=datetime.utcnow)
    fecha_inicio = db.Column(db.DateTime)
    fecha_fin = db.Column(db.DateTime)