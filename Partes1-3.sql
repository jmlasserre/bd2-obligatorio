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
    idAgente NUMBER(10) GENERATED ALWAYS AS IDENTITY PRIMARY KEY, -- recuperado de https://stackoverflow.com/a/78012822.
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
BEGIN
    IF :NEW.fechaDeRegistro > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'La fecha de registro de un usuario no puede ser mayor a la fecha actual.');
    END IF;
END;

-- RNE02
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_CREACION
BEFORE INSERT OR UPDATE ON Agente
FOR EACH ROW
BEGIN
    IF :NEW.fechaCreacion > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20001, 'La fecha de creación de un agente no puede ser mayor a la fecha actual.');
    END IF;
END;

-- RNE03
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_NO_PERTENECE
BEFORE INSERT OR UPDATE ON Pertenece
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idAgente;
    IF v_estado = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20002, 'Un agente suspendido no puede pertenecer a una comunidad.');
    END IF;
END;

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

-- RNE04
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_VOTO
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idAgente;
    IF v_estado = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20003, 'Un agente suspendido no puede emitir votos.');
    END IF;
END;

CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_MODERA
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idAgente;
    IF v_estado = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Un agente suspendido no puede moderar contenidos.');
    END IF;
END;

CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_SUSP_CREA_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(10);
BEGIN
    SELECT estado INTO v_estado
    FROM Agente
    WHERE idAgente = :NEW.idAgente;
    IF v_estado = 'Suspendido' THEN
        RAISE_APPLICATION_ERROR(-20005, 'Un agente suspendido no puede crear contenido.');
    END IF;
END;

-- RNE05
CREATE OR REPLACE TRIGGER VALIDAR_FECHAS_CEDE_RECLAMO
BEFORE INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_fechaRec DATE;
BEGIN
    SELECT fechaReclamo INTO v_fechaRec
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    IF v_fechaRec > :NEW.fechaCesion THEN
        RAISE_APPLICATION_ERROR(-20006, 'Una cesión no puede responder a un reclamo hecho después de esta.');
    END IF;
END;

-- RNE06
CREATE OR REPLACE TRIGGER VALIDAR_CEDE_USUARIOS_DIFF
BEFORE INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_usuarioRec NUMBER(10);
BEGIN
    SELECT emailUsuario INTO v_usuarioRec
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    IF v_usuarioRec = :NEW.emailUsuarioCed THEN
        RAISE_APPLICATION_ERROR(-20007, 'Un usuario no puede cederse agentes a sí mismo.');
    END IF;
END;

-- RNE07
CREATE OR REPLACE TRIGGER VALIDAR_CEDE_USUARIO_ADMINISTRA_AGENTE
BEFORE INSERT OR UPDATE ON Cede
FOR EACH ROW
DECLARE
    v_agente NUMBER(10);
    v_emailAdmin VARCHAR2(70);
BEGIN
    SELECT idAgente INTO v_agente
    FROM Reclamo
    WHERE idReclamo = :NEW.idReclamo;
    SELECT emailAdmin INTO v_emailAdmin
    FROM Agente
    WHERE idAgente = v_agente;
    IF v_emailAdmin <> :NEW.emailUsuarioCed THEN
        RAISE_APPLICATION_ERROR(-20008, 'Un usuario no puede ceder un agente que no administra.');
    END IF;
END;

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
END;
    
-- RNE09
CREATE OR REPLACE TRIGGER VALIDAR_FECHACREACION_COMUNIDAD
BEFORE INSERT OR UPDATE ON Comunidad
FOR EACH ROW
BEGIN
    IF :NEW.fechaCreacion > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20009, 'La fecha de creación de una comunidad no puede ser posterior a la fecha actual.');
    END IF;
END;

-- RNE10
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_PERTENECE_COMUNIDAD_VOTO
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM Pertenece p
    JOIN Contenido c ON p.idComunidad = c.idComunidad
    WHERE p.idAgente = :NEW.idAgente
    AND c.idContenido = :NEW.idContenido;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Un agente no puede emitir votos sobre contenidos de comunidades a las que no pertenece.');
    END IF;
END;
    
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_PERTENECE_COMUNIDAD_ACCION
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM Pertenece p
    JOIN Contenido c ON p.idComunidad = c.idComunidad
    WHERE p.idAgente = :NEW.idAgente
    AND c.idContenido = :NEW.idContenido;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Un agente no puede moderar contenidos de comunidades a las que no pertenece.');
    END IF;
END;

CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_PERTENECE_COMUNIDAD_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_existe NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_existe
    FROM Pertenece p
    WHERE p.idAgente = :NEW.idCreador
    AND p.idComunidad = :NEW.idComunidad;

    IF v_existe = 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Un agente no puede crear contenido en una comunidad si no pertenece a ella.');
    END IF;
END;

-- RNE11
CREATE OR REPLACE TRIGGER VALIDAR_COMUNIDAD_ARCHIVADA_NO_PUBS
BEFORE INSERT OR UPDATE ON Publicacion
FOR EACH ROW
DECLARE
    v_com NUMBER;
    v_archivada CHAR(1);
BEGIN
    SELECT idComunidad INTO v_com
    FROM Contenido
    WHERE idContenido = :NEW.idPub;
    
    SELECT archivada INTO v_archivada
    FROM Comunidad
    WHERE idComunidad = v_com;

    IF v_archivada = 'Y' THEN
        RAISE_APPLICATION_ERROR(-20013, 'Una comunidad archivada no acepta nuevas publicaciones.');
    END IF;
END;

-- RNE12
CREATE OR REPLACE TRIGGER VALIDAR_FECHACREACION_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
BEGIN
    IF :NEW.fechaCreacion > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20014, 'La fecha de creación de un contenido no puede ser posterior a la fecha actual.');
    END IF;
END;

-- RNE13
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_CREADOR_CONTENIDO
BEFORE INSERT OR UPDATE ON Contenido
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(20);
BEGIN
    SELECT tipo INTO v_tipo
    FROM Agente
    WHERE idAgente = :NEW.idCreador;

    IF v_tipo != 'Generador de contenido' THEN
        RAISE_APPLICATION_ERROR(-20015, 'Solo los agentes generadores de contenido pueden crear contenido.');
    END IF;
END;

-- RNE14
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_ACTIVO_CONTENIDO
BEFORE INSERT OR UPDATE ON CONTENIDO
FOR EACH ROW
DECLARE
    v_part VARCHAR2(20);
BEGIN
    SELECT participacion INTO v_part
    FROM Pertenece
    WHERE idAgente = :NEW.idCreador AND idComunidad = :NEW.idComunidad;

    IF v_part != 'Miembro activo' THEN
        RAISE_APPLICATION_ERROR(-20016, 'Solo los agentes activos pueden crear contenido.');
    END IF;
END;

-- RNE15
CREATE OR REPLACE TRIGGER VALIDAR_NO_CITA_AUTOREF
BEFORE INSERT OR UPDATE ON Cita
FOR EACH ROW
BEGIN
    IF :NEW.idOriginal = :NEW.idNueva THEN
        RAISE_APPLICATION_ERROR(-20017, 'Una publicación no puede citarse a sí misma.');
    END IF;
END;

-- RNE16
CREATE OR REPLACE TRIGGER VALIDAR_VOTO_PUB_NO_ELIM
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
DECLARE
    v_count NUMBER;
    v_estado VARCHAR2(15);
    v_pub NUMBER(10);
BEGIN
    SELECT COUNT(*) INTO v_count
    FROM Publicacion
    WHERE idPub = :NEW.idContenido;

    IF v_count > 0 THEN
        SELECT estado INTO v_estado
        FROM Publicacion
        WHERE idPub = :NEW.idContenido;
    ELSE
        SELECT idPubOriginal INTO v_pub
        FROM Comentario
        WHERE idComentario = :NEW.idContenido;

        SELECT estado INTO v_estado
        FROM Publicacion
        WHERE idPub = :NEW.idContenido;

        IF v_estado = 'Eliminada' THEN
            RAISE_APPLICATION_ERROR(-20018, 'Un comentario de una publicación eliminada no puede recibir votos.');
        END IF;
    END IF;

    IF v_estado = 'Eliminada' THEN
        RAISE_APPLICATION_ERROR(-20019, 'Una publicación eliminada no puede recibir votos.');
    END IF;
END;

CREATE OR REPLACE TRIGGER VALIDAR_COMENTARIO_A_PUB_ELIM
BEFORE INSERT OR UPDATE ON Comentario
FOR EACH ROW
DECLARE
    v_estado VARCHAR2(15);
BEGIN
    SELECT estado INTO v_estado
    FROM Publicacion
    WHERE idPub = :NEW.idPubOriginal;

    IF v_estado = 'Eliminada' OR v_estado = 'Archivada' THEN
        RAISE_APPLICATION_ERROR(-20020, 'Una publicación eliminada no puede recibir comentarios.');
    END IF;
END;

-- RNE17
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_EMISION_VOTO
BEFORE INSERT OR UPDATE ON Voto
FOR EACH ROW
BEGIN
    IF :NEW.fechaEmision > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20021, 'La fecha de emisión de un voto no puede ser posterior a la actual.');
    END IF;
END;

-- RNE18
CREATE OR REPLACE TRIGGER VALIDAR_AGENTE_ES_MODERADOR
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(25);
BEGIN
    SELECT tipo INTO v_tipo
    FROM Agente
    WHERE idAgente = :NEW.idAgente;

    IF v_tipo != 'Moderador' THEN
        RAISE_APPLICATION_ERROR(-20022, 'Solo los moderadores pueden supervisar contenidos.');
    END IF;
END;

-- RNE19
CREATE OR REPLACE TRIGGER VALIDAR_MODERADOR_PERTENECE_COMUNIDAD
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_com NUMBER;
    v_count NUMBER;
BEGIN
    SELECT idComunidad into v_com
    FROM Contenido
    WHERE idContenido = :NEW.idContenido;

    SELECT COUNT(*) INTO v_count
    FROM Pertenece
    WHERE idAgente = :NEW.idAgente AND idComunidad = v_com;

    IF v_count = 0 THEN
        RAISE_APPLICATION_ERROR(-20023, 'Un moderador debe pertenecer a una comunidad para supervisar su contenido.');
    END IF;
END;

-- RNE20
CREATE OR REPLACE TRIGGER VALIDAR_FECHA_ACCION
BEFORE INSERT OR UPDATE ON Accion
FOR EACH ROW
DECLARE
    v_fechaCreacion DATE;
BEGIN
    IF :NEW.fechaAccion > SYSDATE THEN
        RAISE_APPLICATION_ERROR(-20024, 'La fecha de realización de una acción no puede ser posterior a la fecha actual.');
    ELSE
        SELECT fechaCreacion INTO v_fechaCreacion
        FROM Contenido
        WHERE idContenido = :NEW.idContenido;

        IF :NEW.fechaAccion < v_fechaCreacion THEN
            RAISE_APPLICATION_ERROR(-20025, 'La fecha de realización de una acción no puede ser anterior a la fecha de creación del contenido afectado.');
        END IF;
    END IF;
END;

-- RNE21
CREATE OR REPLACE TRIGGER VALIDAR_COMENTARIO_NO_AUTOREF
BEFORE INSERT OR UPDATE ON Comentario
FOR EACH ROW
BEGIN
    IF :NEW.idContenido = :NEW.idComentario THEN
        RAISE_APPLICATION_ERROR(-20026, 'Un comentario no puede responderse a si mismo.');
    END IF;
END;

-- RNE22
CREATE OR REPLACE TRIGGER VALIDAR_COMENTARIO_RESPUESTA_MISMA_PUB_ORIGINAL
BEFORE INSERT OR UPDATE ON Comentario
FOR EACH ROW
DECLARE
    v_pubOriginal NUMBER(10);
BEGIN
    IF :NEW.idPubOriginal != :NEW.idContenido THEN
        SELECT idPubOriginal INTO v_pubOriginal
        FROM Comentario
        WHERE idComentario = :NEW.idContenido;

        IF v_pubOriginal != :NEW.idPubOriginal THEN
            RAISE_APPLICATION_ERROR(-20027, 'Un comentario que responde a otro debe pertenecer a la misma publicación.');
        END IF;
    END IF;
END;

-- RNE23
CREATE OR REPLACE TRIGGER ACTUALIZAR_PUNTUACION_VOTO
AFTER INSERT OR UPDATE ON Voto
FOR EACH ROW
BEGIN
    IF :NEW.tipo = 'Positivo' THEN
        UPDATE Contenido
        SET puntuacion = puntuacion + 1
        WHERE idContenido = :NEW.idContenido;
    ELSE
        UPDATE Contenido
        SET puntuacion = puntuacion - 1
        WHERE idContenido = :NEW.idContenido;
    END IF;
END;

-- RNE24
CREATE OR REPLACE TRIGGER ACTUALIZAR_VISIBILIDAD_ACCION
AFTER INSERT OR UPDATE ON Accion
FOR EACH ROW
BEGIN
    IF :NEw.tipo = 'Abrir' THEN
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
END;

/*
    PARTE 2
*/

-- 2.1.
CREATE OR REPLACE PROCEDURE REGISTRAR_AGENTE (
    p_emailUsuario IN VARCHAR2,
    p_nombre IN VARCHAR2,
    p_descAgente IN VARCHAR2,
    p_estado IN VARCHAR2,
    p_configuracion IN VARCHAR2,
    p_tipo IN VARCHAR2,
    p_fechaCreacion IN DATE,
    p_fechaAplicacion IN DATE,
    p_version IN VARCHAR2,
    p_descConfig IN VARCHAR2
) AS
    v_idAgente NUMBER(10);
BEGIN
    INSERT INTO Agente VALUES (p_nombre, p_fechaCreacion, p_descAgente, p_estado, p_configuracion, p_tipo, p_emailUsuario)
    RETURNING idAgente INTO v_idAgente;

    INSERT INTO Configuracion VALUES (v_idAgente, p_version, p_fechaAplicacion, p_descConfig);
END;

-- 2.2.
CREATE OR REPLACE PROCEDURE TRANSFERIR_AGENTE (
    p_emailUsuarioRec IN VARCHAR2,
    p_idAgente IN NUMBER,
    p_fechaReclamo IN DATE,
    p_emailUsuarioCed IN VARCHAR2,
    p_fechaCesion IN DATE
) AS
    v_idReclamo NUMBER(10);
BEGIN
    INSERT INTO Reclamo VALUES (p_emailUsuarioRec, p_idAgente, p_fechaReclamo)
    RETURNING idReclamo INTO v_idReclamo;

    INSERT INTO Cede VALUES (v_idReclamo, p_emailUsuarioCed, p_fechaCesion);
END;

-- 2.3.
CREATE OR REPLACE PROCEDURE GENERAR_PUBLICACION (
    p_idAgente IN NUMBER,
    p_idComunidad IN NUMBER,
    p_estado IN VARCHAR2,
    p_fechaCreacion IN DATE,
    p_puntuacion IN NUMBER,
    p_texto IN VARCHAR2
) AS
BEGIN
    INSERT INTO Contenido VALUES(
        p_idAgente,
        p_idComunidad,
        p_estado,
        p_fechaCreacion,
        p_puntuacion,
        p_texto
    );
END;

-- 2.6.
CREATE OR REPLACE PROCEDURE MODERAR_CONTENIDO (
    p_idModerador IN NUMBER,
    p_idContenido IN NUMBER,
    p_fechaAccion IN DATE,
    p_tipo IN VARCHAR2
) AS
BEGIN
    INSERT INTO Accion VALUES (
        p_idModerador,
        p_idContenido,
        p_fechaAccion,
        p_tipo 
    );
END;

-- 2.8.
CREATE OR REPLACE PROCEDURE OBTENER_TOP10_PUBS_ACTIVAS_EN_COMUNIDAD (
    p_idAdminFiltro IN NUMBER DEFAULT -1,
    p_idComunidad IN NUMBER,
    p_idAdmin IN NUMBER,
    p_cursorRes OUT SYS_REFCURSOR
) AS
BEGIN
    IF p_filtrarPorAdmin = -1 THEN
        OPEN p_cursorRes FOR
            SELECT c.puntuacion, c.titulo, c.fechaCreacion, a.nombre, a.emailAdmin
            FROM Publicacion p
            INNER JOIN Contenido c ON c.idContenido = p.idPub
            INNER JOIN Agente a ON a.idAgente = c.idCreador
            WHERE c.idComunidad = p_idComunidad
            AND p.estado = 'Abierta'
            AND c.puntuacion > 0
            AND c.fechaCreacion > (SYSDATE - 30)
            ORDER BY c.puntuacion DESC
            FETCH FIRST 10 ROWS ONLY;
    ELSE
        OPEN p_cursorRes FOR
            SELECT c.puntuacion, c.titulo, c.fechaCreacion, a.nombre, a.emailAdmin
            FROM Publicacion p
            INNER JOIN Contenido c ON c.idContenido = p.idPub
            INNER JOIN Agente a ON a.idAgente = c.idCreador
            WHERE c.idComunidad = p_idComunidad
            AND c.idCreador = p_idAdminFiltro
            AND p.estado = 'Abierta'
            AND c.puntuacion > 0
            AND c.fechaCreacion > (SYSDATE - 30)
            ORDER BY c.puntuacion DESC
            FETCH FIRST 10 ROWS ONLY;
        RAISE_APPLICATION_ERROR(-20028, 'Parámetro inválido.');
    END IF;
END;

/*
    PARTE 3 
*/