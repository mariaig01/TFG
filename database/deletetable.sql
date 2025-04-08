-- Eliminar el usuario (debería eliminar también la prenda, publicación, comentario, preferencias, etc.)
DELETE FROM usuarios WHERE id = 1;

-- Consultas de comprobación para verificar que los registros relacionados fueron eliminados
SELECT * FROM prendas;
SELECT * FROM publicaciones;
SELECT * FROM comentarios;
SELECT * FROM preferencias;
