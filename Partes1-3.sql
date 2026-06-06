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
    idAgente NUMBER(10) PRIMARY KEY,
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
)

CREATE TABLE Comunidad (
    idComunidad NUMBER(10) PRIMARY KEY,
    nombre VARCHAR2(21) NOT NULL UNIQUE, -- Inspirado en la extensión máxima para nombres de subreddits: https://www.reddit.com/r/NoStupidQuestions/comments/1g3e2j6/why_is_the_subreddit_character_limit_21_why_is_it/
    descripcion VARCHAR2(100),
    fechaCreacion DATE NOT NULL,
    tema VARCHAR2(20) NOT NULL,
    archivada CHAR(1) CHECK (archivada IN ('Y', 'N'))
);

CREATE TABLE Accion (
    idAccion NUMBER(10) PRIMARY KEY,
    idAgente NUMBER(10) REFERENCES Agente,
    idContenido NUMBER(10) REFERENCES Contenido,
    fechaAccion DATE NOT NULL,
    tipo VARCHAR2(10) NOT NULL CHECK (tipo IN ('Ocultar', 'Eliminar', 'Cerrar')),
)

CREATE TABLE Configuracion (
    idConfig NUMBER(10),
    idAgente NUMBER(10) REFERENCES Agente,
    version VARCHAR2(10) NOT NULL,
    fechaAplicacion DATE NOT NULL,
    descripcion VARCHAR2(50),
    PRIMARY KEY (idConfig, idAgente)
);

CREATE TABLE Contenido (
    idContenido NUMBER(10) PRIMARY KEY,
    idCreador NUMBER(10) NOT NULL REFERENCES Agente(idAgente),
    estado VARCHAR2(10) CHECK (estado IN ('Abierta', 'Cerrada', 'Eliminada')),
    fechaCreacion DATE NOT NULL,
    puntuacion NUMBER(10) NOT NULL DEFAULT 0,
    texto VARCHAR2(40000) NOT NULL -- Nos inspiramos en la extensión máxima de un post de Reddit: https://www.reddit.com/r/help/comments/nykedi/how_many_characters_can_you_have_in_a_reddit_post/
);

CREATE TABLE Comentario (
    idComentario NUMBER(10) PRIMARY KEY REFERENCES Contenido(idContenido),
    idContenido NUMBER(10) NOT NULL REFERENCES Contenido CHECK (idContenido <> idComentario)
);

CREATE TABLE Publicacion (
    idPub NUMBER(10) PRIMARY KEY REFERENCES Contenido(idContenido),
    idComunidad NUMBER(10) NOT NULL REFERENCES Comunidad,
    titulo VARCHAR2(300) NOT NULL
);

CREATE TABLE Cita (
    idOriginal NUMBER(10) REFERENCES Publicacion(idPub),
    idNueva NUMBER(10) REFERENCES Publicacion(idPub) CHECK (idNueva <> idOriginal),
    fechaCita DATE NOT NULL,
    PRIMARY KEY (idOriginal, idNueva)
);

CREATE TABLE Agente_Pertenece_Comunidad (
    idAgente NUMBER(10) REFERENCES Agente,
    idComunidad NUMBER(10) REFERENCES Comunidad,
    participacion VARCHAR2(15) NOT NULL CHECK (participacion IN ('Seguidor', 'Miembro activo')),
    PRIMARY KEY (idAgente, idComunidad)
);

CREATE TABLE Voto (
    idVoto NUMBER(10) PRIMARY KEY,
    idAgente NUMBER(10) NOT NULL REFERENCES Agente,
    idContenido NUMBER(10) NOT NULL REFERENCES Contenido,
    fechaEmision DATE NOT NULL,
);

-- RNEs


/*
    PARTE 2
*/

/*
    PARTE 3 
*/