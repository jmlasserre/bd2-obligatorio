-- Aquí va todo lo relacionado a SQL del proyecto

/*
    PARTE 1
*/

-- DDL

DROP TABLE Usuario CASCADE CONSTRAINTS;
DROP TABLE Usuario_Telefono CASCADE CONSTRAINTS;
DROP TABLE Agente CASCADE CONSTRAINTS;
DROP TABLE Reclamo CASCADE CONSTRAINTS;
DROP TABLE Cede CASCADE CONSTRAINTS;
DROP TABLE Accion CASCADE CONSTRAINTS;
DROP TABLE Configuracion CASCADE CONSTRAINTS;
DROP TABLE Contenido CASCADE CONSTRAINTS;
DROP TABLE Comentario CASCADE CONSTRAINTS;
DROP TABLE Publicacion CASCADE CONSTRAINTS;
DROP TABLE Cita CASCADE CONSTRAINTS;
DROP TABLE Comunidad CASCADE CONSTRAINTS;
DROP TABLE Pertenece CASCADE CONSTRAINTS;
DROP TABLE Voto CASCADE CONSTRAINTS;

CREATE TABLE Usuario (
    email VARCHAR2(70) PRIMARY KEY,
    alias VARCHAR2(50) NOT NULL UNIQUE,
    nombre VARCHAR2(30) NOT NULL,
    apellido VARCHAR2(30) NOT NULL,
    paisDeResidencia VARCHAR2(30) NOT NULL,
    estado VARCHAR2(10) NOT NULL CHECK (estado IN ('Activo', 'Suspendido')),
    fechaDeRegistro DATE NOT NULL
);

CREATE TABLE Usuario_Telefono (
    email VARCHAR2(70) NOT NULL REFERENCES Usuario,
    telefono VARCHAR2(20),
    PRIMARY KEY (email, telefono)
);

CREATE TABLE Agente (
    nombre VARCHAR2(30) NOT NULL,
    idAgente NUMBER(10) GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY, -- recuperado de https://stackoverflow.com/a/78012822.
    fechaCreacion DATE NOT NULL,
    descripcion VARCHAR2(50),
    estado VARCHAR2(10) NOT NULL CHECK (estado IN ('Activo', 'Suspendido')),
    configuracion VARCHAR2(10) CHECK (configuracion IN ('Simple', 'Compuesta')),
    tipo VARCHAR2(25) CHECK (tipo IN ('Generador de contenido', 'Moderador', 'Observador')),
    emailAdmin VARCHAR2(70) NOT NULL REFERENCES Usuario(email)
);

CREATE TABLE Reclamo (
    idReclamo NUMBER(10) PRIMARY KEY,
    emailUsuario VARCHAR2(70) NOT NULL REFERENCES Usuario(email),
    idAgente NUMBER(10) NOT NULL REFERENCES Agente,
    fechaReclamo DATE NOT NULL
);

CREATE TABLE Cede (
    idReclamo NUMBER(10) REFERENCES Reclamo,
    emailUsuarioCed VARCHAR2(70) REFERENCES Usuario(email),
    fechaCesion DATE NOT NULL,
    PRIMARY KEY (idReclamo, emailUsuarioCed)
);

CREATE TABLE Comunidad (
    idComunidad NUMBER(10) PRIMARY KEY,
    nombre VARCHAR2(21) NOT NULL UNIQUE, -- Inspirado en la extensión máxima para nombres de subreddits: https://www.reddit.com/r/NoStupidQuestions/comments/1g3e2j6/why_is_the_subreddit_character_limit_21_why_is_it/
    descripcion VARCHAR2(100),
    fechaCreacion DATE NOT NULL,
    tema VARCHAR2(20) NOT NULL,
    archivada CHAR(1) NOT NULL CHECK (archivada IN ('Y', 'N'))
);

CREATE TABLE Configuracion (
    idConfig NUMBER(10) GENERATED ALWAYS AS IDENTITY,
    idAgente NUMBER(10) REFERENCES Agente,
    version VARCHAR2(10) NOT NULL,
    fechaAplicacion DATE NOT NULL,
    tipo VARCHAR2(10) CHECK (tipo IN ('Simple', 'Compuesta')),
    descripcion VARCHAR2(50),
    PRIMARY KEY (idConfig, idAgente)
);

CREATE TABLE Contenido (
    idContenido NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idCreador NUMBER(10) NOT NULL REFERENCES Agente(idAgente),
    idComunidad NUMBER(10) NOT NULL REFERENCES Comunidad,
    estado VARCHAR2(10) CHECK (estado IN ('Abierta', 'Cerrada', 'Eliminada')),
    fechaCreacion DATE NOT NULL,
    puntuacion NUMBER(10) DEFAULT 0 NOT NULL,
    texto VARCHAR2(1000) NOT NULL
);

CREATE TABLE Accion (
    idAccion NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    idAgente NUMBER(10) REFERENCES Agente,
    idContenido NUMBER(10) REFERENCES Contenido,
    fechaAccion DATE NOT NULL,
    tipo VARCHAR2(10) NOT NULL CHECK (tipo IN ('Abrir', 'Eliminar', 'Cerrar'))
);

CREATE TABLE Publicacion (
    idPub NUMBER(10) PRIMARY KEY REFERENCES Contenido(idContenido),
    estado VARCHAR2(10) CHECK (estado IN ('Abierta', 'Cerrada', 'Eliminada')),
    titulo VARCHAR2(300) NOT NULL
);

CREATE TABLE Comentario (
    idComentario NUMBER(10) PRIMARY KEY REFERENCES Contenido(idContenido),
    idContenido NUMBER(10) NOT NULL REFERENCES Contenido,
    idPubOriginal NUMBER(10) NOT NULL REFERENCES Publicacion(idPub)
);

CREATE TABLE Cita (
    idOriginal NUMBER(10) REFERENCES Publicacion(idPub),
    idNueva NUMBER(10) REFERENCES Publicacion(idPub),
    fechaCita DATE NOT NULL,
    PRIMARY KEY (idOriginal, idNueva)
);

CREATE TABLE Pertenece (
    idAgente NUMBER(10) REFERENCES Agente,
    idComunidad NUMBER(10) REFERENCES Comunidad,
    participacion VARCHAR2(15) NOT NULL CHECK (participacion IN ('Seguidor', 'Miembro activo')),
    PRIMARY KEY (idAgente, idComunidad)
);

CREATE TABLE Voto (
    idVoto NUMBER(10) PRIMARY KEY,
    idAgente NUMBER(10) NOT NULL REFERENCES Agente,
    idContenido NUMBER(10) NOT NULL REFERENCES Contenido,
    fechaEmision DATE NOT NULL
);

-- RNEs

-- RNE01
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_REGISTRO
BEFORE INSERT OR UPDATE ON Usuario
FOR EACH ROW
DECLARE
    e_fecha_futura EXCEPTION;
BEGIN
    IF :NEW.fechaDeRegistro > SYSDATE THEN
        RAISE e_fecha_futura;
    END IF;
EXCEPTION
    WHEN e_fecha_futura THEN
        RAISE_APPLICATION_ERROR(-20001, 'La fecha de registro de un usuario no puede ser mayor a la fecha actual.');
END;
/

-- RNE02
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_CREACION
BEFORE INSERT OR UPDATE ON Agente
FOR EACH ROW
DECLARE
    e_fecha_futura EXCEPTION;
BEGIN
    IF :NEW.fechaCreacion > SYSDATE THEN
        RAISE e_fecha_futura;
    END IF;
EXCEPTION
    WHEN e_fecha_futura THEN
        RAISE_APPLICATION_ERROR(-20002, 'La fecha de creación de un agente no puede ser mayor a la fecha actual.');
END;
/

-- RNE03
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_CREA_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
    e_agente_suspendido EXCEPTION;
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idCreador;
    
    IF v_estado = 'Suspendido' THEN
        RAISE e_agente_suspendido;
    END IF;
EXCEPTION
    WHEN e_agente_suspendido THEN
        RAISE_APPLICATION_ERROR(-20005, 'Un agente suspendido no puede crear contenido.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20090, 'El agente creador especificado no existe.');
END;
/

-- también necesitamos uno que elimine las tuplas correspondientes cuando se actualiza el estado de un agente.
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_ELIMINAR_PERTENECE
BEFORE UPDATE ON Agente
FOR EACH ROW
BEGIN
    IF :OLD.estado != 'Suspendido' AND :NEW.estado = 'Suspendido' THEN
        DELETE FROM Pertenece
        WHERE idAgente = :NEW.idAgente;
    END IF;
END;
/

-- RNE04
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_VOTO
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
    e_agente_suspendido EXCEPTION;
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idAgente;
    
    IF v_estado = 'Suspendido' THEN
        RAISE e_agente_suspendido;
    END IF;
EXCEPTION
    WHEN e_agente_suspendido THEN
        RAISE_APPLICATION_ERROR(-20003, 'Un agente suspendido no puede emitir votos.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20091, 'El agente votante especificado no existe.');
END;
/

CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_MODERA
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
    e_agente_suspendido EXCEPTION;
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idAgente;
    
    IF v_estado = 'Suspendido' THEN
        RAISE e_agente_suspendido;
    END IF;
EXCEPTION
    WHEN e_agente_suspendido THEN
        RAISE_APPLICATION_ERROR(-20004, 'Un agente suspendido no puede moderar contenidos.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20092, 'El agente moderador especificado no existe.');
END;
/

-- RNE05
CREATE OR REPLACE TRIGGER VALIDAR_FECHAS_CEDE_RECLAMO
BEFORE INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_fechaRec DATE;
    e_fecha_invalida EXCEPTION;
BEGIN
    SELECT fechaReclamo INTO v_fechaRec
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    
    IF v_fechaRec > :NEW.fechaCesion THEN
        RAISE e_fecha_invalida;
    END IF;
EXCEPTION
    WHEN e_fecha_invalida THEN
        RAISE_APPLICATION_ERROR(-20006, 'Una cesión no puede responder a un reclamo hecho después de esta.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20093, 'El reclamo asociado a la cesión no existe.');
END;
/

-- RNE06
CREATE OR REPLACE TRIGGER VALIDAR_CEDE_USUARIOS_DIFF
BEFORE INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_usuarioRec VARCHAR2(70);
    e_autocesion EXCEPTION;
BEGIN
    SELECT emailUsuario INTO v_usuarioRec
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    
    IF v_usuarioRec = :NEW.emailUsuarioCed THEN
        RAISE e_autocesion;
    END IF;
EXCEPTION
    WHEN e_autocesion THEN
        RAISE_APPLICATION_ERROR(-20007, 'Un usuario no puede cederse agentes a sí mismo.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20094, 'El reclamo asociado a esta cesión no existe.');
END;
/

-- RNE07
CREATE OR REPLACE TRIGGER VALIDAR_CEDE_USUARIO_ADMINISTRA_AGENTE
BEFORE INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_agente NUMBER(10);
    v_emailAdmin VARCHAR2(70);
    e_no_es_administrador EXCEPTION;
BEGIN
    SELECT idAgente INTO v_agente
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    
    SELECT emailAdmin INTO v_emailAdmin
    FROM Agente
    WHERE idAgente = v_agente;
    
    IF v_emailAdmin <> :NEW.emailUsuarioCed THEN
        RAISE e_no_es_administrador;
    END IF;
EXCEPTION
    WHEN e_no_es_administrador THEN
        RAISE_APPLICATION_ERROR(-20008, 'Un usuario no puede ceder un agente que no administra.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20095, 'No se encontraron registros del reclamo o del agente relacionado.');
END;
/

-- RNE08
CREATE OR REPLACE TRIGGER ACTUALIZAR_CEDE_NUEVO_ADMIN
AFTER INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_agente NUMBER(10);
    v_emailRec VARCHAR2(70);
BEGIN
    SELECT emailUsuario, idAgente INTO v_emailRec, v_agente
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    
    UPDATE Agente
    SET emailAdmin = v_emailRec
    WHERE idAgente = v_agente;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20096, 'Error al procesar la cesión automática: El reclamo no existe.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20097, 'Error inesperado al actualizar el nuevo administrador del agente.');
END;
/

-- RNE09
CREATE OR REPLACE TRIGGER VALIDAR_FECHACREACION_COMUNIDAD
BEFORE INSERT OR UPDATE ON Comunidad
FOR EACH ROW
DECLARE
    e_fecha_futura EXCEPTION;
BEGIN
    IF :NEW.fechaCreacion > SYSDATE THEN
        RAISE e_fecha_futura;
    END IF;
EXCEPTION
    WHEN e_fecha_futura THEN
        RAISE_APPLICATION_ERROR(-20009, 'La fecha de creación de una comunidad no puede ser posterior a la fecha actual.');
END;
/

-- RNE10
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_PERTENECE_COMUNIDAD_VOTO
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    v_existe NUMBER;
    e_no_pertenece EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM Pertenece p
    JOIN Contenido c ON p.idComunidad = c.idComunidad
    WHERE p.idAgente = :NEW.idAgente
    AND c.idContenido = :NEW.idContenido;

    IF v_existe = 0 THEN
        RAISE e_no_pertenece;
    END IF;
EXCEPTION
    WHEN e_no_pertenece THEN
        RAISE_APPLICATION_ERROR(-20010, 'Un agente no puede emitir votos sobre contenidos de comunidades a las que no pertenece.');
END;
/

CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_PERTENECE_COMUNIDAD_ACCION
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_existe NUMBER;
    e_no_pertenece EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM Pertenece p
    JOIN Contenido c ON p.idComunidad = c.idComunidad
    WHERE p.idAgente = :NEW.idAgente
    AND c.idContenido = :NEW.idContenido;

    IF v_existe = 0 THEN
        RAISE e_no_pertenece;
    END IF;
EXCEPTION
    WHEN e_no_pertenece THEN
        RAISE_APPLICATION_ERROR(-20011, 'Un agente no puede moderar contenidos de comunidades a las que no pertenece.');
END;
/

CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_PERTENECE_COMUNIDAD_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_existe NUMBER;
    e_no_pertenece EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM Pertenece p
    WHERE p.idAgente = :NEW.idCreador
    AND p.idComunidad = :NEW.idComunidad;

    IF v_existe = 0 THEN
        RAISE e_no_pertenece;
    END IF;
EXCEPTION
    WHEN e_no_pertenece THEN
        RAISE_APPLICATION_ERROR(-20012, 'Un agente no puede crear contenido en una comunidad si no pertenece a ella.');
END;
/

-- RNE11
CREATE OR REPLACE TRIGGER VALIDAR_COMUNIDAD_ARCHIVADA_NO_PUBS
BEFORE INSERT OR UPDATE ON Publicacion
FOR EACH ROW
DECLARE
    v_com NUMBER;
    v_archivada CHAR(1);
    e_comunidad_archivada EXCEPTION;
BEGIN
    SELECT idComunidad INTO v_com
    FROM Contenido
    WHERE idContenido = :NEW.idPub;
    
    SELECT archivada INTO v_archivada
    FROM Comunidad
    WHERE idComunidad = v_com;

    IF v_archivada = 'Y' THEN
        RAISE e_comunidad_archivada;
    END IF;
EXCEPTION
    WHEN e_comunidad_archivada THEN
        RAISE_APPLICATION_ERROR(-20013, 'Una comunidad archivada no acepta nuevas publicaciones.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20098, 'No se encontró la publicación o la comunidad asociada.');
END;
/

-- RNE12
CREATE OR REPLACE TRIGGER VALIDAR_FECHACREACION_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    e_fecha_futura EXCEPTION;
BEGIN
    IF :NEW.fechaCreacion > SYSDATE THEN
        RAISE e_fecha_futura;
    END IF;
EXCEPTION
    WHEN e_fecha_futura THEN
        RAISE_APPLICATION_ERROR(-20014, 'La fecha de creación de un contenido no puede ser posterior a la fecha actual.');
END;
/

-- RNE13
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_CREADOR_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(25);
    e_tipo_invalido EXCEPTION;
BEGIN
    SELECT tipo INTO v_tipo
    FROM Agente
    WHERE idAgente = :NEW.idCreador;

    IF v_tipo != 'Generador de contenido' THEN
        RAISE e_tipo_invalido;
    END IF;
EXCEPTION
    WHEN e_tipo_invalido THEN
        RAISE_APPLICATION_ERROR(-20015, 'Solo los agentes generadores de contenido pueden crear contenido.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20101, 'El agente creador especificado no existe.');
END;
/

-- RNE14
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_ACTIVO_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_part VARCHAR2(20);
    e_no_es_activo EXCEPTION;
BEGIN
    SELECT participacion INTO v_part
    FROM Pertenece
    WHERE idAgente = :NEW.idCreador AND idComunidad = :NEW.idComunidad;

    IF v_part != 'Miembro activo' THEN
        RAISE e_no_es_activo;
    END IF;
EXCEPTION
    WHEN e_no_es_activo THEN
        RAISE_APPLICATION_ERROR(-20016, 'Solo los agentes activos pueden crear contenido.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20102, 'El agente no pertenece a la comunidad especificada.');
END;
/

-- RNE15
CREATE OR REPLACE TRIGGER VALIDAR_NO_CITA_AUTOREF
BEFORE INSERT OR UPDATE ON Cita
FOR EACH ROW
DECLARE
    e_autocita EXCEPTION;
BEGIN
    IF :NEW.idOriginal = :NEW.idNueva THEN
        RAISE e_autocita;
    END IF;
EXCEPTION
    WHEN e_autocita THEN
        RAISE_APPLICATION_ERROR(-20017, 'Una publicación no puede citarse a sí misma.');
END;
/

-- RNE16
CREATE OR REPLACE TRIGGER VALIDAR_VOTO_PUB_NO_ELIM
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    v_count NUMBER;
    v_estado VARCHAR2(15);
    v_pub NUMBER(10);
    e_pub_eliminada EXCEPTION;
    e_com_eliminado EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Publicacion
    WHERE idPub = :NEW.idContenido;

    IF v_count > 0 THEN
        SELECT estado INTO v_estado
        FROM Publicacion
        WHERE idPub = :NEW.idContenido;
        
        IF v_estado = 'Eliminada' THEN
            RAISE e_pub_eliminada;
        END IF;
    ELSE
        SELECT idPubOriginal INTO v_pub
        FROM Comentario
        WHERE idComentario = :NEW.idContenido;

        SELECT estado INTO v_estado
        FROM Publicacion
        WHERE idPub = v_pub; -- Corrección de variable para evaluar el post original del comentario

        IF v_estado = 'Eliminada' THEN
            RAISE e_com_eliminado;
        END IF;
    END IF;
EXCEPTION
    WHEN e_pub_eliminada THEN
        RAISE_APPLICATION_ERROR(-20019, 'Una publicación eliminada no puede recibir votos.');
    WHEN e_com_eliminado THEN
        RAISE_APPLICATION_ERROR(-20018, 'Un comentario de una publicación eliminada no puede recibir votos.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20103, 'El contenido o la publicación original asociada no existe.');
END;
/

CREATE OR REPLACE TRIGGER VALIDAR_COMENTARIO_A_PUB_ELIM
BEFORE INSERT OR UPDATE ON Comentario
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(15);
    e_pub_invalida EXCEPTION;
BEGIN
    SELECT estado INTO v_estado
    FROM Publicacion
    WHERE idPub = :NEW.idPubOriginal;

    IF v_estado = 'Eliminada' OR v_estado = 'Archivada' THEN
        RAISE e_pub_invalida;
    END IF;
EXCEPTION
    WHEN e_pub_invalida THEN
        RAISE_APPLICATION_ERROR(-20020, 'Una publicación eliminada o archivada no puede recibir comentarios.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20104, 'La publicación original especificada no existe.');
END;
/

-- RNE17
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_EMISION_VOTO
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    e_fecha_futura EXCEPTION;
BEGIN
    IF :NEW.fechaEmision > SYSDATE THEN
        RAISE e_fecha_futura;
    END IF;
EXCEPTION
    WHEN e_fecha_futura THEN
        RAISE_APPLICATION_ERROR(-20021, 'La fecha de emisión de un voto no puede ser posterior a la actual.');
END;
/

-- RNE18
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_ES_MODERADOR
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(25);
    e_no_es_moderador EXCEPTION;
BEGIN
    SELECT tipo INTO v_tipo
    FROM Agente
    WHERE idAgente = :NEW.idAgente;

    IF v_tipo != 'Moderador' THEN
        RAISE e_no_es_moderador;
    END IF;
EXCEPTION
    WHEN e_no_es_moderador THEN
        RAISE_APPLICATION_ERROR(-20022, 'Solo los moderadores pueden supervisar contenidos.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20105, 'El agente supervisor especificado no existe.');
END;
/

-- RNE19
CREATE OR REPLACE TRIGGER VALIDAR_MODERADOR_PERTENECE_COMUNIDAD
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_com NUMBER;
    v_count NUMBER;
    e_no_pertenece EXCEPTION;
BEGIN
    SELECT idComunidad INTO v_com
    FROM Contenido
    WHERE idContenido = :NEW.idContenido;

    SELECT COUNT(*) INTO v_count
    FROM Pertenece
    WHERE idAgente = :NEW.idAgente AND idComunidad = v_com;

    IF v_count = 0 THEN
        RAISE e_no_pertenece;
    END IF;
EXCEPTION
    WHEN e_no_pertenece THEN
        RAISE_APPLICATION_ERROR(-20023, 'Un moderador debe pertenecer a una comunidad para supervisar su contenido.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20106, 'No se encontró el contenido asociado a la acción.');
END;
/

-- RNE20
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_ACCION
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_fechaCreacion DATE;
    e_fecha_futura EXCEPTION;
    e_fecha_anterior EXCEPTION;
BEGIN
    IF :NEW.fechaAccion > SYSDATE THEN
        RAISE e_fecha_futura;
    ELSE
        SELECT fechaCreacion INTO v_fechaCreacion
        FROM Contenido
        WHERE idContenido = :NEW.idContenido;

        IF :NEW.fechaAccion < v_fechaCreacion THEN
            RAISE e_fecha_anterior;
        END IF;
    END IF;
EXCEPTION
    WHEN e_fecha_futura THEN
        RAISE_APPLICATION_ERROR(-20024, 'La fecha de realización de una acción no puede ser posterior a la fecha actual.');
    WHEN e_fecha_anterior THEN
        RAISE_APPLICATION_ERROR(-20025, 'La fecha de realización de una acción no puede ser anterior a la fecha de creación del contenido afectado.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20107, 'No se encontró el contenido afectado por la acción.');
END;
/

-- RNE21
CREATE OR REPLACE TRIGGER VALIDAR_COMENTARIO_NO_AUTOREF
BEFORE INSERT OR UPDATE ON Comentario
FOR EACH ROW
DECLARE
    e_auto_respuesta EXCEPTION;
BEGIN
    IF :NEW.idContenido = :NEW.idComentario THEN
        RAISE e_auto_respuesta;
    END IF;
EXCEPTION
    WHEN e_auto_respuesta THEN
        RAISE_APPLICATION_ERROR(-20026, 'Un comentario no puede responderse a sí mismo.');
END;
/

-- RNE22
CREATE OR REPLACE TRIGGER VALIDAR_COMENTARIO_RESPUESTA_MISMA_PUB_ORIGINAL
BEFORE INSERT OR UPDATE ON Comentario
FOR EACH ROW
DECLARE
    v_pubOriginal NUMBER(10);
    e_distinta_publicacion EXCEPTION;
BEGIN
    IF :NEW.idPubOriginal != :NEW.idContenido THEN
        SELECT idPubOriginal INTO v_pubOriginal
        FROM Comentario
        WHERE idComentario = :NEW.idContenido;

        IF v_pubOriginal != :NEW.idPubOriginal THEN
            RAISE e_distinta_publicacion;
        END IF;
    END IF;
EXCEPTION
    WHEN e_distinta_publicacion THEN
        RAISE_APPLICATION_ERROR(-20027, 'Un comentario que responde a otro debe pertenecer a la misma publicación.');
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20108, 'El comentario al que se intenta responder no existe.');
END;
/

-- RNE23
CREATE OR REPLACE TRIGGER ACTUALIZAR_PUNTUACION_VOTO
AFTER INSERT OR UPDATE ON Voto
FOR EACH ROW
BEGIN
    UPDATE Contenido
    SET puntuacion = puntuacion + 1
    WHERE idContenido = :NEW.idContenido;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20109, 'Error inesperado al actualizar la puntuación del contenido.');
END;
/

-- RNE24
CREATE OR REPLACE TRIGGER ACTUALIZAR_VISIBILIDAD_ACCION
AFTER INSERT OR UPDATE ON Accion
FOR EACH ROW
BEGIN
    IF :NEW.tipo = 'Abrir' THEN
        UPDATE Contenido
        SET estado = 'Abierta'
        WHERE idContenido = :NEW.idContenido;
    ELSIF :NEW.tipo = 'Eliminar' THEN
        UPDATE Contenido
        SET estado = 'Eliminada'
        WHERE idContenido = :NEW.idContenido;
    ELSE
        UPDATE Contenido
        SET estado = 'Cerrada'
        WHERE idContenido = :NEW.idContenido;
    END IF;
EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20110, 'Error inesperado al actualizar el estado de visibilidad del contenido.');
END;
/

-- RNE25
CREATE OR REPLACE TRIGGER ACTUALIZAR_CONFIG_AGENTE
AFTER INSERT OR UPDATE ON Configuracion 
-- Se ejecuta DESPUÉS de que la fila entró a la tabla(evitar mutacion de tabla)
DECLARE

BEGIN
    UPDATE Agente a
    SET a.configuracion = (
        SELECT c.tipo
        FROM Configuracion c
        WHERE c.idAgente = a.idAgente
        AND c.fechaAplicacion = (
            SELECT MAX(c2.fechaAplicacion)
            FROM Configuracion c2
            WHERE c2.idAgente = a.idAgente
        )
        FETCH FIRST 1 ROWS ONLY
    )
    -- Solo modificamos los agentes que están en el proceso actual (optimizacion)
    WHERE a.idAgente IN (SELECT DISTINCT idAgente FROM Configuracion);

EXCEPTION
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20111, 'Error al procesar la actualización de la configuración más nueva.');
END;
/

-- PARTE C, DATOS DE PRUEBA (vaciar las tablas con cascada antes de insertar)

-- ============================================================================
-- 1. USUARIOS Y TELÉFONOS
-- ============================================================================
INSERT INTO Usuario (email, alias, nombre, apellido, paisDeResidencia, estado, fechaDeRegistro)
VALUES ('admin1@red.com', 'SuperAdmin', 'Carlos', 'Gómez', 'Argentina', 'Activo', TO_DATE('2026-01-01', 'YYYY-MM-DD'));

INSERT INTO Usuario (email, alias, nombre, apellido, paisDeResidencia, estado, fechaDeRegistro)
VALUES ('user1@red.com', 'GamerPro', 'Ana', 'Martínez', 'Uruguay', 'Activo', TO_DATE('2026-02-01', 'YYYY-MM-DD'));

INSERT INTO Usuario (email, alias, nombre, apellido, paisDeResidencia, estado, fechaDeRegistro)
VALUES ('user2@red.com', 'ModMaster', 'Luis', 'Rodríguez', 'Chile', 'Activo', TO_DATE('2026-02-15', 'YYYY-MM-DD'));

INSERT INTO Usuario_Telefono (email, telefono) VALUES ('admin1@red.com', '+541112345678');
INSERT INTO Usuario_Telefono (email, telefono) VALUES ('user1@red.com', '+59899123456');

-- ============================================================================
-- 2. AGENTES (IDs autoincrementales: 1, 2, 3...)
-- ============================================================================
-- Agente ID 1
INSERT INTO Agente (nombre, fechaCreacion, descripcion, estado, configuracion, tipo, emailAdmin)
VALUES ('BotRedactor_A', TO_DATE('2026-03-01', 'YYYY-MM-DD'), 'Genera posts de noticias', 'Activo', 'Simple', 'Generador de contenido', 'admin1@red.com');

-- Agente ID 2
INSERT INTO Agente (nombre, fechaCreacion, descripcion, estado, configuracion, tipo, emailAdmin)
VALUES ('BotMod_B', TO_DATE('2026-03-01', 'YYYY-MM-DD'), 'Filtra spam', 'Activo', 'Simple', 'Moderador', 'admin1@red.com');

-- Agente ID 3
INSERT INTO Agente (nombre, fechaCreacion, descripcion, estado, configuracion, tipo, emailAdmin)
VALUES ('BotRedactor_C', TO_DATE('2026-03-05', 'YYYY-MM-DD'), 'Postea memes y cultura pop', 'Activo', 'Simple', 'Generador de contenido', 'user2@red.com');

SELECT idAgente, nombre FROM Agente ORDER BY idAgente;

-- ============================================================================
-- 3. COMUNIDADES
-- ============================================================================
INSERT INTO Comunidad (idComunidad, nombre, descripcion, fechaCreacion, tema, archivada)
VALUES (10, 'gaming_latam', 'Comunidad de videojuegos en LATAM', TO_DATE('2026-01-10', 'YYYY-MM-DD'), 'Videojuegos', 'N');

INSERT INTO Comunidad (idComunidad, nombre, descripcion, fechaCreacion, tema, archivada)
VALUES (20, 'cine_y_series', 'Hablemos de películas', TO_DATE('2026-01-20', 'YYYY-MM-DD'), 'Entretenimiento', 'N');

-- ============================================================================
-- 4. PERTENENCIA 
-- ============================================================================
INSERT INTO Pertenece (idAgente, idComunidad, participacion) VALUES (1, 10, 'Miembro activo');
INSERT INTO Pertenece (idAgente, idComunidad, participacion) VALUES (2, 10, 'Miembro activo');
INSERT INTO Pertenece (idAgente, idComunidad, participacion) VALUES (3, 20, 'Miembro activo');
INSERT INTO Pertenece (idAgente, idComunidad, participacion) VALUES (3, 10, 'Miembro activo'); 

-- ============================================================================
-- 5. CONTENIDO, PUBLICACIONES Y COMENTARIOS
-- ============================================================================
-- Contenido ID 1 (Publicación)
INSERT INTO Contenido (idCreador, idComunidad, estado, fechaCreacion, puntuacion, texto)
VALUES (1, 10, 'Abierta', TO_DATE('2026-03-10', 'YYYY-MM-DD'), 0, '¡Bienvenidos al foro de Gaming! ¿Qué juegan hoy?');

INSERT INTO Publicacion (idPub, estado, titulo)
VALUES (1, 'Abierta', 'Primer Post Oficial de Gaming');

-- Contenido ID 2 (Comentario respondiendo al Contenido 1)
INSERT INTO Contenido (idCreador, idComunidad, estado, fechaCreacion, puntuacion, texto)
VALUES (3, 10, 'Abierta', TO_DATE('2026-03-11', 'YYYY-MM-DD'), 0, '¡Hola! Yo estoy jugando RPGs.');

INSERT INTO Comentario (idComentario, idContenido, idPubOriginal)
VALUES (2, 1, 1);

-- ============================================================================
-- 6. ACCIONES, VOTOS Y CONFIGURACIONES
-- ============================================================================
-- Voto al post inicial (ID 1) por parte del Moderador (Agente 2)
INSERT INTO Voto (idVoto, idAgente, idContenido, fechaEmision)
VALUES (100, 2, 1, TO_DATE('2026-03-12', 'YYYY-MM-DD'));

-- Acción de moderación: El Agente 2 cierra el post ID 1
INSERT INTO Accion (idAgente, idContenido, fechaAccion, tipo)
VALUES (2, 1, TO_DATE('2026-03-15', 'YYYY-MM-DD'), 'Cerrar');

-- Actualización de Configuración del Agente 1 (Ejecuta RNE25)
INSERT INTO Configuracion (idAgente, version, fechaAplicacion, tipo, descripcion)
VALUES (1, 'v1.1', TO_DATE('2026-04-01', 'YYYY-MM-DD'), 'Compuesta', 'Actualización de algoritmos');

-- ============================================================================
-- 7. RECLAMOS Y CESIONES
-- ============================================================================
-- Reclamo sobre el Agente 1
INSERT INTO Reclamo (idReclamo, emailUsuario, idAgente, fechaReclamo)
VALUES (500, 'user2@red.com', 1, TO_DATE('2026-04-10', 'YYYY-MM-DD'));

-- Cesión del Agente 1 (Ejecuta RNE08 y cambia su admin a user2@red.com)
INSERT INTO Cede (idReclamo, emailUsuarioCed, fechaCesion)
VALUES (500, 'admin1@red.com', TO_DATE('2026-04-11', 'YYYY-MM-DD'));

COMMIT;

-- ============================================================================
-- CASOS DE PRUEBA: VALIDACIÓN DE RESTRICCIONES (REGLAS DE NEGOCIO)
-- Cada uno de estos bloques DEBE fallar y lanzar la excepción controlada.
-- ============================================================================

SET SERVEROUTPUT ON;

-- ----------------------------------------------------------------------------
-- PRUEBA 1: Validar RNE01 (Fecha de registro futura en Usuario)
-- ----------------------------------------------------------------------------
PROMPT Ejecutando Prueba 1 (RNE01)...;

INSERT INTO Usuario (email, alias, nombre, apellido, paisDeResidencia, estado, fechaDeRegistro)
VALUES ('viajero_tiempo@red.com', 'Marty', 'Marty', 'McFly', 'Uruguay', 'Activo', SYSDATE + 10);


-- ----------------------------------------------------------------------------
-- PRUEBA 2: Validar RNE14 (Solo Miembros Activos crean contenido)
-- ----------------------------------------------------------------------------
PROMPT Ejecutando Prueba 2 (RNE14)...;

INSERT INTO Contenido (idCreador, idComunidad, estado, fechaCreacion, puntuacion, texto)
VALUES (1, 20, 'Abierta', TO_DATE('2026-03-12', 'YYYY-MM-DD'), 0, 'Intento de posteo en comunidad ajena');


-- ----------------------------------------------------------------------------
-- PRUEBA 3: Validar RNE03 (Agente Suspendido crea contenido)
-- ----------------------------------------------------------------------------
PROMPT Ejecutando Prueba 3 (RNE03)...;

-- Primero suspendemos al Agente 1 (Dueño de los inserts de contenido)
UPDATE Agente SET estado = 'Suspendido' WHERE idAgente = 1;

-- Ahora intentamos que cree un nuevo contenido estando suspendido
INSERT INTO Contenido (idCreador, idComunidad, estado, fechaCreacion, puntuacion, texto)
VALUES (1, 10, 'Abierta', TO_DATE('2026-03-16', 'YYYY-MM-DD'), 0, 'Post de un agente suspendido');

-- Restauramos el estado para no romper las pruebas siguientes
UPDATE Agente SET estado = 'Activo' WHERE idAgente = 1;


-- ----------------------------------------------------------------------------
-- PRUEBA 4: Validar RNE25 (Actualización de Configuración Más Nueva)
-- ----------------------------------------------------------------------------
PROMPT Ejecutando Prueba 4 (RNE25)...;

-- Paso 4.1: Insertar configuración del PASADO (No debe alterar al Agente 1)
INSERT INTO Configuracion (idAgente, version, fechaAplicacion, tipo, descripcion)
VALUES (1, 'v1.0-vieja', TO_DATE('2026-01-01', 'YYYY-MM-DD'), 'Simple', 'Configuración vieja de prueba');

-- Verificamos: El agente DEBE seguir en 'Compuesta' (Ignoró la vieja)
SELECT idAgente, configuracion FROM Agente WHERE idAgente = 1;


-- Paso 4.2: Insertar configuración del FUTURO (Debe actualizar al Agente 1)
-- Cambiamos de 'Compuesta' a 'Simple' (que es un valor válido que ya usaste en los inserts base)
INSERT INTO Configuracion (idAgente, version, fechaAplicacion, tipo, descripcion)
VALUES (1, 'v2.0-nueva', TO_DATE('2026-05-01', 'YYYY-MM-DD'), 'Simple', 'Configuración nueva de prueba');

-- Verificamos: Ahora el agente DEBE haber cambiado a 'Simple' exitosamente
SELECT idAgente, configuracion FROM Agente WHERE idAgente = 1;


-- ----------------------------------------------------------------------------
-- PRUEBA 5: Validar Excepción NO_DATA_FOUND integrada
-- ----------------------------------------------------------------------------
PROMPT Ejecutando Prueba 5 (RNE19)...;

INSERT INTO Accion (idAgente, idContenido, fechaAccion, tipo)
VALUES (999, 1, TO_DATE('2026-03-15', 'YYYY-MM-DD'), 'Cerrar');

ROLLBACK; -- Limpiamos los experimentos para dejar la base en su estado original


/*
    PARTE 2
*/

-- 2.1.
CREATE OR REPLACE PROCEDURE REGISTRAR_AGENTE (
    p_emailUsuario    IN VARCHAR2,
    p_nombre          IN VARCHAR2,
    p_descAgente      IN VARCHAR2,
    p_estado          IN VARCHAR2,
    p_configuracion   IN VARCHAR2,
    p_tipo            IN VARCHAR2,
    p_fechaCreacion   IN DATE,
    p_fechaAplicacion IN DATE,
    p_version         IN VARCHAR2,
    p_descConfig      IN VARCHAR2
) AS
    v_idAgente    NUMBER(10);
    v_existeUser  NUMBER;
    e_user_no_existe EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_existeUser
    FROM Usuario
    WHERE email = p_emailUsuario;

    IF v_existeUser = 0 THEN
        RAISE e_user_no_existe;
    END IF;

    INSERT INTO Agente (nombre, fechaCreacion, descripcion, estado, configuracion, tipo, emailAdmin)
    VALUES (p_nombre, p_fechaCreacion, p_descAgente, p_estado, p_configuracion, p_tipo, p_emailUsuario)
    RETURNING idAgente INTO v_idAgente;

    INSERT INTO Configuracion (idAgente, version, fechaAplicacion, tipo, descripcion)
    VALUES (v_idAgente, p_version, p_fechaAplicacion, p_configuracion, p_descConfig);
EXCEPTION
    WHEN e_user_no_existe THEN
        RAISE_APPLICATION_ERROR(-20203, 'El email del administrador provisto no corresponde a un usuario registrado.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20201, 'Error general al registrar el agente: ' || SQLERRM);
END REGISTRAR_AGENTE;
/

-- 2.2.
CREATE OR REPLACE PROCEDURE TRANSFERIR_AGENTE (
    p_emailUsuarioRec IN VARCHAR2,
    p_idAgente        IN NUMBER,
    p_fechaReclamo    IN DATE,
    p_emailUsuarioCed IN VARCHAR2,
    p_fechaCesion     IN DATE
) AS
    v_idReclamo      NUMBER(10);
    v_existeRec      NUMBER;
    v_existeAgente   NUMBER;
    e_datos_invalidos EXCEPTION;
BEGIN
    -- Validamos que el usuario receptor y el agente existan en la base de datos
    SELECT COUNT(*) INTO v_existeRec FROM Usuario WHERE email = p_emailUsuarioRec;
    SELECT COUNT(*) INTO v_existeAgente FROM Agente WHERE idAgente = p_idAgente;

    IF v_existeRec = 0 OR v_existeAgente = 0 THEN
        RAISE e_datos_invalidos;
    END IF;

    INSERT INTO Reclamo (emailUsuario, idAgente, fechaReclamo)
    VALUES (p_emailUsuarioRec, p_idAgente, p_fechaReclamo)
    RETURNING idReclamo INTO v_idReclamo;

    INSERT INTO Cede (idReclamo, emailUsuarioCed, fechaCesion)
    VALUES (v_idReclamo, p_emailUsuarioCed, p_fechaCesion);

EXCEPTION
    WHEN e_datos_invalidos THEN
        RAISE_APPLICATION_ERROR(-20204, 'El usuario receptor o el agente especificado no existen.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20205, 'Error general al transferir el agente: ' || SQLERRM);
END TRANSFERIR_AGENTE;
/

CREATE OR REPLACE PROCEDURE GENERAR_PUBLICACION (
    p_idAgente      IN NUMBER,
    p_idComunidad   IN NUMBER,
    p_estado        IN VARCHAR2,
    p_fechaCreacion IN DATE,
    p_puntuacion    IN NUMBER,
    p_texto         IN VARCHAR2
) AS
    v_idContenido          NUMBER(10);
    v_pertenece            NUMBER;
    e_agente_no_autorizado EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_pertenece 
    FROM Pertenece 
    WHERE idAgente = p_idAgente AND idComunidad = p_idComunidad;

    IF v_pertenece = 0 THEN
        RAISE e_agente_no_autorizado;
    END IF;

    INSERT INTO Contenido (idCreador, idComunidad, estado, fechaCreacion, puntuacion, texto)
    VALUES (p_idAgente, p_idComunidad, p_estado, p_fechaCreacion, p_puntuacion, p_texto)
    RETURNING idContenido INTO v_idContenido;

    INSERT INTO Publicacion (idPub, estado, titulo)
    VALUES (v_idContenido, p_estado, SUBSTR(p_texto, 1, 50)); -- Tomamos los primeros 50 caracteres como título por defecto
EXCEPTION
    WHEN e_agente_no_autorizado THEN
        RAISE_APPLICATION_ERROR(-20206, 'El agente no pertenece a la comunidad seleccionada y no puede publicar.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20207, 'Error general al generar la publicación: ' || SQLERRM);
END GENERAR_PUBLICACION;
/

-- 2.6.
CREATE OR REPLACE PROCEDURE MODERAR_CONTENIDO (
    p_idModerador IN NUMBER,
    p_idContenido IN NUMBER,
    p_fechaAccion IN DATE,
    p_tipo        IN VARCHAR2
) AS
    v_existeContenido NUMBER;
    v_existeMod       NUMBER;
    e_datos_invalidos EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_existeContenido FROM Contenido WHERE idContenido = p_idContenido;
    SELECT COUNT(*) INTO v_existeMod       FROM Agente    WHERE idAgente = p_idModerador;

    IF v_existeContenido = 0 OR v_existeMod = 0 THEN
        RAISE e_datos_invalidos;
    END IF;

    INSERT INTO Accion (idAgente, idContenido, fechaAccion, tipo)
    VALUES (
        p_idModerador,
        p_idContenido,
        p_fechaAccion,
        p_tipo 
    );
EXCEPTION
   WHEN e_datos_invalidos THEN
        RAISE_APPLICATION_ERROR(-20208, 'El ID del contenido o el ID del moderador especificado no existen en la base de datos.');
        
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20209, 'Error general al registrar la acción de moderación: ' || SQLERRM);
END MODERAR_CONTENIDO;
/

-- 2.8.
CREATE OR REPLACE PROCEDURE OBTENER_TOP10_PUBS_ACTIVAS_EN_COMUNIDAD (
    p_idAdminFiltro IN NUMBER DEFAULT NULL, -- Filtro opcional por ID de administrador
    p_idComunidad   IN NUMBER,
    p_idAdmin       IN NUMBER,              -- ID del administrador que ejecuta el servicio
    p_cursorRes     OUT SYS_REFCURSOR   -- https://www.oracletutorial.com/plsql-tutorial/plsql-cursor-variables/

) AS
    v_pertenece     NUMBER;
    e_no_autorizado EXCEPTION;
BEGIN
    SELECT COUNT(*) INTO v_pertenece 
    FROM Pertenece 
    WHERE idAgente = p_idAdmin AND idComunidad = p_idComunidad;

    IF v_pertenece = 0 THEN
        RAISE e_no_autorizado;
    END IF;

    IF p_idAdminFiltro IS NULL THEN
        OPEN p_cursorRes FOR
            SELECT c.puntuacion, p.titulo, c.fechaCreacion, a.nombre, a.emailAdmin
            FROM Publicacion p
            INNER JOIN Contenido c ON c.idContenido = p.idPub
            INNER JOIN Agente a    ON a.idAgente = c.idCreador
            WHERE c.idComunidad = p_idComunidad
            AND p.estado = 'Abierta'
            AND c.puntuacion > 0
            AND c.fechaCreacion > (SYSDATE - 30)
            ORDER BY c.puntuacion DESC
            FETCH FIRST 10 ROWS ONLY;
    ELSE
        OPEN p_cursorRes FOR
            SELECT c.puntuacion, p.titulo, c.fechaCreacion, a.nombre, a.emailAdmin
            FROM Publicacion p
            INNER JOIN Contenido c ON c.idContenido = p.idPub
            INNER JOIN Agente a    ON a.idAgente = c.idCreador
            WHERE c.idComunidad = p_idComunidad
            AND c.idCreador = p_idAdminFiltro
            AND p.estado = 'Abierta'
            AND c.puntuacion > 0
            AND c.fechaCreacion > (SYSDATE - 30)
            ORDER BY c.puntuacion DESC
            FETCH FIRST 10 ROWS ONLY;
    END IF;
EXCEPTION
    WHEN e_no_autorizado THEN
        RAISE_APPLICATION_ERROR(-20210, 'El agente que consulta no está autorizado en esta comunidad.');
    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20211, 'Error al procesar el ranking de publicaciones: ' || SQLERRM);
END OBTENER_TOP10_PUBS_ACTIVAS_EN_COMUNIDAD;
/

/*
    PARTE 3 
*/

/* 

Consulta:

Para una comunidad, obtener los alias y nombres de los usuarios administradores de los agentes
autores de los comentarios con la menor puntuación negativa publicados en los últimos tres meses,
así como el nombre del agente y el título de la publicación original. El listado debería estar ordenado
ascendentemente por la puntuación de los comentarios.
Tablas: Usuario, Agente, Contenido, Pertenece, Comentario

Funcionalidad: de negocio
Justificación: permite al sistema identificar quiénes son los usuarios administradores de agentes que han
realizado comentarios controversiales, abriendo varias posibilidades: restringirles acceso,
cambiar el estado del agente o incluso realizar acciones sobre las publicaciones. Pueden tratarse de agentes que
no aporten a la red, sino que activamente provoquen a la comunidad.

*/

-- Fuente: https://stackoverflow.com/questions/11799344/how-can-i-see-the-sql-execution-plan-in-oracle
EXPLAIN PLAN FOR
    SELECT u.alias, u.nombre AS "NOMBRE_USUARIO", a.nombre AS "NOMBRE_AGENTE", a.configuracion, p.titulo, co.puntuacion
    FROM Comunidad c, Contenido co, Comentario com, Publicacion p, Pertenece pe, Agente a, Usuario u
    WHERE co.puntuacion < 0
    AND co.idComunidad = c.idComunidad
    AND com.idComentario = co.idContenido
    AND p.idPub = com.idPubOriginal
    AND pe.idComunidad = c.idComunidad
    AND a.idAgente = pe.idAgente
    AND u.email = a.emailAdmin
    AND p.estado = 'Abierta'
    AND co.fechaCreacion > ADD_MONTHS(SYSDATE, -3)
    AND c.tema = 'Política'
    ORDER BY co.puntuacion ASC;
    
SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY (FORMAT=>'ALL +OUTLINE'))

/*
1. Operaciones principales:
- Joins naturales
- Proyecciones (al final, para mostrar los resultados)
- Selecciones varias
- Ordenamiento (por puntuación)

2. 
- Joins => nested loops. Explicar cómo se usan.
- Proyecciones sobre el final para mostrar los resultados.
- Selecciones: hay full scan, 
https://stackoverflow.com/questions/21462886/does-table-access-by-index-rowid-means-optimizer-using-index-or-table

3.



4.



*/