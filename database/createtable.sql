-- Crear tipo ENUM para estaciones
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'estacion_enum') THEN
        CREATE TYPE estacion_enum AS ENUM ('Primavera', 'Verano', 'Otoño', 'Invierno', 'Cualquiera');
    END IF;
END $$;

DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'emocion_enum') THEN
        CREATE TYPE emocion_enum AS ENUM ('feliz', 'triste', 'enfadado', 'sorprendido', 'miedo', 'asco', 'neutro');
    END IF;
END $$;


DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'tipo_prenda_enum') THEN
        CREATE TYPE tipo_prenda_enum AS ENUM (
            'Camisa',
            'Camiseta',
            'Blusa',
            'Top',
            'Vestido',
            'Falda',
            'Pantalón',
            'Vaqueros',
            'Shorts',
            'Sudadera',
            'Jersey',
            'Rebeca',
            'Corset',
            'Chaqueta',
            'Abrigo',
            'Blazer',
            'Chaleco',
            'Cárdigan',
            'Mono',
            'Traje',
            'Chándal',
            'Mallas',
            'Bikini',
            'Polo',
            'Zapato',
            'Bota',
            'Sandalia',
            'Tacón',
            'Zapatilla deportiva',
            'Cinturón',
            'Bufanda',
            'Pañuelo',
            'Medias',
            'Gorro',
            'Sombrero',
            'Guantes',
            'Bolso',
            'Mochila',
            'Reloj',
            'Pulsera',
            'Collar',
            'Pendientes',
            'Gafas de sol',
            'Otro'
        );
    END IF;
END
$$;



-- Tabla usuarios
CREATE TABLE usuarios (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    nombre VARCHAR(50),
    apellido VARCHAR(50),
    email VARCHAR(100) UNIQUE,
    contraseña VARCHAR(255),
    fecha_registro TIMESTAMP,
    foto_perfil VARCHAR(255),
    bio TEXT,
    verificado BOOLEAN,
    rol VARCHAR(20),
    token VARCHAR(255),
    reset_token VARCHAR(255),
    reset_token_expiration TIMESTAMP,
    fecha_modificacion TIMESTAMP
);

-- Tabla categorias
CREATE TABLE categorias (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100) UNIQUE NOT NULL
);

-- Tabla prendas
CREATE TABLE prendas (
    id SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    nombre VARCHAR(100),
    descripcion TEXT,
    precio DECIMAL(10,2),
    talla VARCHAR(10),
    color VARCHAR(30),
    imagen_url VARCHAR(255),
    fecha_agregado TIMESTAMP,
    fecha_modificacion TIMESTAMP,
    tipo tipo_prenda_enum NOT NULL DEFAULT 'Otro',
    emocion emocion_enum NOT NULL DEFAULT 'neutro'
);

-- Tabla preferencias
CREATE TABLE preferencias (
    id SERIAL PRIMARY KEY,
    id_usuario INT UNIQUE REFERENCES usuarios(id) ON DELETE CASCADE,
    tallas TEXT[],
    colores TEXT[],
    otras_preferencias TEXT
);

-- Tabla publicaciones
CREATE TABLE publicaciones (
    id SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    contenido TEXT,
    imagen_url VARCHAR(255),
    fecha_publicacion TIMESTAMP,
    visibilidad VARCHAR(20) DEFAULT 'publico'
        CHECK (visibilidad IN ('publico', 'privado', 'seguidores', 'amigos'))
);

-- Tabla comentarios
CREATE TABLE comentarios (
    id SERIAL PRIMARY KEY,
    id_publicacion INT REFERENCES publicaciones(id) ON DELETE CASCADE,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    texto TEXT,
    fecha_comentario TIMESTAMP
);

-- Tabla mensajes
CREATE TABLE mensajes (
    id SERIAL PRIMARY KEY,
    id_emisor INT REFERENCES usuarios(id) ON DELETE CASCADE,
    id_receptor INT REFERENCES usuarios(id) ON DELETE CASCADE,
    mensaje TEXT,
    id_publicacion INT REFERENCES publicaciones(id),
    fecha_envio TIMESTAMP,
    estado VARCHAR(20)
);

-- Tabla grupos
CREATE TABLE grupos (
    id SERIAL PRIMARY KEY,
    nombre VARCHAR(100),
    descripcion TEXT,
    creador INT REFERENCES usuarios(id) ON DELETE SET NULL,
    fecha_creacion TIMESTAMP
);

-- Tabla favoritos
CREATE TABLE favoritos (
    id SERIAL PRIMARY KEY,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    id_prenda INT REFERENCES prendas(id),
    id_publicacion INT REFERENCES publicaciones(id),
    fecha_agregado TIMESTAMP
);

-- Tabla seguimientos
CREATE TABLE seguimientos (
    id SERIAL PRIMARY KEY,
    id_seguidor INT REFERENCES usuarios(id) ON DELETE CASCADE,
    id_seguido INT REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_inicio TIMESTAMP,
    tipo VARCHAR(20)
);

-- Tabla likes
CREATE TABLE likes (
    id SERIAL PRIMARY KEY,
    id_publicacion INT REFERENCES publicaciones(id) ON DELETE CASCADE,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    fecha_creacion TIMESTAMP
);

-- Tabla grupo_usuarios
CREATE TABLE grupo_usuarios (
    id SERIAL PRIMARY KEY,
    id_grupo INT REFERENCES grupos(id) ON DELETE CASCADE,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    rol VARCHAR(20),
    fecha_ingreso TIMESTAMP
);

-- Tabla mensajes_grupo
CREATE TABLE mensajes_grupo (
    id SERIAL PRIMARY KEY,
    id_grupo INT REFERENCES grupos(id) ON DELETE CASCADE,
    id_usuario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    mensaje TEXT,
    fecha_envio TIMESTAMP
);

-- Tabla preferencias_categorias
CREATE TABLE preferencias_categorias (
    preferencias_id INT REFERENCES preferencias(id) ON DELETE CASCADE,
    categoria_id INT REFERENCES categorias(id) ON DELETE CASCADE,
    estacion estacion_enum NOT NULL,
    PRIMARY KEY (preferencias_id, categoria_id)
);

-- Tabla prendas_categorias
CREATE TABLE prendas_categorias (
    prenda_id INT REFERENCES prendas(id) ON DELETE CASCADE,
    categoria_id INT REFERENCES categorias(id) ON DELETE CASCADE,
    estacion estacion_enum NOT NULL,
    PRIMARY KEY (prenda_id, categoria_id)
);

--Tabla solicitudes_categoria
CREATE TABLE solicitudes_prenda (
    id SERIAL PRIMARY KEY,
    id_prenda INT REFERENCES prendas(id) ON DELETE CASCADE,
    id_remitente INT REFERENCES usuarios(id) ON DELETE CASCADE,
    id_destinatario INT REFERENCES usuarios(id) ON DELETE CASCADE,
    estado VARCHAR(20) DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'aceptada', 'rechazada')),
    fecha_solicitud TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    fecha_inicio TIMESTAMP,
    fecha_fin TIMESTAMP
);


