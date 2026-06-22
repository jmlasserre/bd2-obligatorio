const oracledb = require('oracledb');
const { MongoClient } = require('mongodb');
const config = require('../config');

// --- CONFIGURACIÓN DESDE CONFIG.JS ---
const oracleConfig = config.oracle;
const mongoUri = config.mongo.uri;
const mongoDbName = config.mongo.dbName;
const colEventosName = config.mongo.colecciones.eventos;

async function runETL() {
    let oracleConn, mongoClient;
    try {
        // 1. CONEXIONES
        oracleConn = await oracledb.getConnection(oracleConfig);
        mongoClient = new MongoClient(mongoUri);
        await mongoClient.connect();
        
        const db = mongoClient.db(mongoDbName);
        const colEventos = db.collection(colEventosName);
        console.log('Conexiones establecidas usando config.js.');

        // 2. EXTRACCIÓN Y TRANSFORMACIÓN: EVENTOS
        const eventosResult = await oracleConn.execute(`
            SELECT 'Accion' as fuente, ac.idAccion as id, ac.idAgente, ac.idContenido, ac.fechaAccion as fecha, ac.tipo as tipoEvento,
                   ag.nombre as agNombre, ag.tipo as agTipo
            FROM Accion ac JOIN Agente ag ON ac.idAgente = ag.idAgente
            UNION ALL
            SELECT 'Voto' as fuente, v.idVoto as id, v.idAgente, v.idContenido, v.fechaEmision as fecha, 'Voto' as tipoEvento,
                   ag.nombre as agNombre, ag.tipo as agTipo
            FROM Voto v JOIN Agente ag ON v.idAgente = ag.idAgente
            ORDER BY fecha
        `);

        const documentosEventos = eventosResult.rows.map(row => {
            const [fuente, id, idAgente, idContenido, fecha, tipoEvento, agNombre, agTipo] = row;
            let criticidad = 'baja';
            
            if (tipoEvento === 'Eliminar') criticidad = 'alta';
            else if (tipoEvento === 'Cerrar') criticidad = 'media';
            
            return {
                _id: id,
                tipoEvento: `${fuente} - ${tipoEvento}`,
                criticidad,
                timestamp: fecha,
                infoAgente: { id: idAgente, nombre: agNombre, tipo: agTipo },
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