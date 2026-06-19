require('dotenv').config(); // Carga las variables del archivo .env
const oracledb = require('oracledb');
const { MongoClient } = require('mongodb');

// --- CONFIGURACIÓN DESDE .ENV ---
const oracleConfig = {
    user: process.env.ORACLE_USER,
    password: process.env.ORACLE_PASSWORD,
    connectString: process.env.ORACLE_CONNECT_STRING
};
const mongoUri = process.env.MONGO_URI;
const mongoDbName = process.env.MONGO_DB_NAME;
const colAgentesName = process.env.COL_AGENTES || 'agentes_perfil';
const colEventosName = process.env.COL_EVENTOS || 'eventos';

// Validación básica de variables de entorno
if (!oracleConfig.user || !mongoUri) {
    console.error('Error: Faltan variables de entorno en el archivo .env');
    process.exit(1);
}

async function runETL() {
    let oracleConn, mongoClient;

    try {
        // 1. CONEXIONES
        oracleConn = await oracledb.getConnection(oracleConfig);
        mongoClient = new MongoClient(mongoUri);
        await mongoClient.connect();
        const db = mongoClient.db(mongoDbName);
        const colAgentes = db.collection(colAgentesName);
        const colEventos = db.collection(colEventosName);
        console.log('Conexiones establecidas usando configuración externa.');

        // 2. EXTRACCIÓN Y TRANSFORMACIÓN: AGENTES
        const agentResult = await oracleConn.execute(`
            SELECT a.idAgente, a.nombre, a.tipo, a.estado, a.configuracion, a.emailAdmin, 
                   a.fechaCreacion, a.descripcion, c.version, c.fechaAplicacion, c.descripcion as configDesc,
                   p.idComunidad, p.participacion, com.nombre as nombreComunidad
            FROM Agente a
            LEFT JOIN Configuracion c ON a.idAgente = c.idAgente
            LEFT JOIN Pertenece p ON a.idAgente = p.idAgente
            LEFT JOIN Comunidad com ON p.idComunidad = com.idComunidad
            ORDER BY a.idAgente
        `);

        const agentesMap = new Map();
        for (const row of agentResult.rows) {
            const [id, nombre, tipo, estado, config, email, fecha, desc, cVer, cFecha, cDesc, comId, comPart, comNom] = row;
            if (!agentesMap.has(id)) {
                agentesMap.set(id, {
                    idAgente: id, nombre, tipo, estado, configuracion: config, emailAdmin: email, 
                    fechaCreacion: fecha, descripcion: desc, prompt: "", 
                    historialConfiguraciones: [], comunidades: []
                });
            }
            const agente = agentesMap.get(id);
            if (cVer) agente.historialConfiguraciones.push({ version: cVer, fechaAplicacion: cFecha, descripcion: cDesc });
            if (comId) agente.comunidades.push({ idComunidad: comId, nombre: comNom, participacion: comPart });
        }

        const documentosAgentes = Array.from(agentesMap.values());
        if (documentosAgentes.length > 0) {
            await colAgentes.insertMany(documentosAgentes);
            console.log(`${documentosAgentes.length} perfiles de agentes migrados.`);
        }

        // 3. EXTRACCIÓN Y TRANSFORMACIÓN: EVENTOS
        const eventosResult = await oracleConn.execute(`
            SELECT 'Accion' as fuente, ac.idAccion as id, ac.idAgente, ac.idContenido, ac.fechaAccion as fecha, ac.tipo as tipoEvento,
                   ag.nombre as agNombre, ag.tipo as agTipo, ag.emailAdmin
            FROM Accion ac JOIN Agente ag ON ac.idAgente = ag.idAgente
            UNION ALL
            SELECT 'Voto' as fuente, v.idVoto as id, v.idAgente, v.idContenido, v.fechaEmision as fecha, 'Voto' as tipoEvento,
                   ag.nombre as agNombre, ag.tipo as agTipo, ag.emailAdmin
            FROM Voto v JOIN Agente ag ON v.idAgente = ag.idAgente
            ORDER BY fecha
        `);

        const documentosEventos = eventosResult.rows.map(row => {
            const [fuente, id, idAgente, idContenido, fecha, tipoEvento, agNombre, agTipo, emailAdmin] = row;
            let criticidad = 'baja';
            if (tipoEvento === 'Eliminar') criticidad = 'alta';
            else if (tipoEvento === 'Cerrar') criticidad = 'media';

            return {
                idEvento: id, idAgente, tipoEvento: `${fuente} - ${tipoEvento}`, criticidad, timestamp: fecha,
                infoAgente: { nombre: agNombre, tipo: agTipo, emailAdmin },
                detalles: { idContenido, fuenteOriginal: fuente }
            };
        });

        if (documentosEventos.length > 0) {
            await colEventos.insertMany(documentosEventos);
            console.log(`${documentosEventos.length} eventos migrados.`);
        }

        console.log('Proceso de integración finalizado con éxito.');

    } catch (err) {
        console.error('Error en el ETL:', err);
    } finally {
        if (oracleConn) await oracleConn.close();
        if (mongoClient) await mongoClient.close();
    }
}

runETL();