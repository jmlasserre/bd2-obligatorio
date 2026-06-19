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
        const colEventos = db.collection(colEventosName);
        console.log('Conexiones establecidas usando configuración externa.');

        // 2. EXTRACCIÓN Y TRANSFORMACIÓN: EVENTOS
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
                idEvento: id, 
                idAgente, 
                tipoEvento: `${fuente} - ${tipoEvento}`, 
                criticidad, 
                timestamp: fecha,
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