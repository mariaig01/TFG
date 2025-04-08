
-- Insertar un usuario
INSERT INTO usuarios (nombre, apellido, email, contraseña, fecha_registro, verificado, rol)
VALUES ('Ana', 'Gómez', 'ana@example.com', 'hash123', NOW(), true, 'usuario');

-- Insertar una categoría
INSERT INTO categorias (nombre) VALUES ('Casual');

-- Insertar una prenda asociada al usuario creado
INSERT INTO prendas (id_usuario, nombre, descripcion, precio, talla, color, fecha_agregado)
VALUES (1, 'Camiseta', 'Camiseta blanca básica', 15.99, 'M', 'Blanco', NOW());

-- Insertar una publicación del usuario
INSERT INTO publicaciones (id_usuario, contenido, fecha_publicacion)
VALUES (1, 'Hoy hace buen día para vestir de blanco', NOW());

-- Insertar una preferencia
INSERT INTO preferencias (id_usuario, tallas, colores, otras_preferencias)
VALUES (1, ARRAY['M'], ARRAY['Blanco'], 'Prefiere ropa cómoda');

-- Insertar un comentario en la publicación
INSERT INTO comentarios (id_publicacion, id_usuario, texto, fecha_comentario)
VALUES (1, 1, '¡Totalmente de acuerdo!', NOW());

