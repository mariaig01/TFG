
CREATE OR REPLACE FUNCTION agregar_creador_a_grupo()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO grupo_usuarios (id_grupo, id_usuario, rol, fecha_ingreso)
  VALUES (NEW.id, NEW.creador, 'administrador', NOW());
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_grupo_insert
AFTER INSERT ON grupos
FOR EACH ROW
WHEN (NEW.creador IS NOT NULL)
EXECUTE FUNCTION agregar_creador_a_grupo();
