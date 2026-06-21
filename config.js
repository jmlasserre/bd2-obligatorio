// Oracle
const ORACLE_USER = "BD_2";
const ORACLE_PASSWORD = "root";
const ORACLE_CONNECT_STRING = "localhost:1521/xe";

// MongoDB
const MONGO_URI = "mongodb://localhost:27017";
const MONGO_DB_NAME = "test";

// Colecciones
const COL_EVENTOS = "eventos";

// Parámetros para consultas
// 5.1
const ID_AGENTE_DESEADO_5_1 = 1;
const FECHA_DESDE = "2025-01-12T01:30:00"; // ¡mantener ese formato para no romper la consulta!
const FECHA_HASTA = "2026-06-20T15:30:00"; // lo mismo acá

// 5.2
const ID_AGENTE_DESEADO_5_3 = 2;
const HORA_INICIO = 0; // 0-23
const HORA_FIN = 23; // 0-23

const config = {
  oracle: {
    user: ORACLE_USER,
    password: ORACLE_PASSWORD,
    connectString: ORACLE_CONNECT_STRING,
  },
  mongo: {
    uri: MONGO_URI,
    dbName: MONGO_DB_NAME,
    colecciones: {
      eventos: COL_EVENTOS,
    },
  },
  consultas: {
    "5_1": {
      idAgenteDeseado: ID_AGENTE_DESEADO_5_1,
      fechaDesde: FECHA_DESDE,
      fechaHasta: FECHA_HASTA,
    },
    "5_3": {
      idAgenteDeseado: ID_AGENTE_DESEADO_5_3,
      horaInicio: HORA_INICIO,
      horaFin: HORA_FIN,
    },
  },
};

module.exports = config;