// Aquí va todo lo relacionado a SQL del proyecto

// Usuario
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
    email VARCHAR2(70) REFERENCES Usuario,
    telefono VARCHAR2(20),
    PRIMARY KEY (email, telefono)
);

CREATE TABLE Agente (
    nombre VARCHAR2(30) NOT NULL,
    idAgente NUMBER PRIMARY KEY,
    fechaCreacion DATE NOT NULL,
    descripcion VARCHAR2(50),
    estado VARCHAR2(10) NOT NULL CHECK (estado IN ('Activo', 'Suspendido')),
    configuracion VARCHAR2(10) CHECK (configuracion IN ('Simple', 'Compuesta'))
);

CREATE TABLE Configuracion (
    idConfig NUMBER,
    idAgente NUMBER REFERENCES Agente,
    version VARCHAR2(10) NOT NULL,
    fechaAplicacion DATE NOT NULL,
    descripcion VARCHAR2(50)
    PRIMARY KEY (idConfig, idAgente)
)

CREATE TABLE Contenido (

);

CREATE TABLE Comunidad (

);