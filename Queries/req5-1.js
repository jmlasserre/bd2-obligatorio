require('dotenv').config({ path: '../.env' });
const { MongoClient } = require('mongodb');

if (typeof global.crypto === 'undefined') {
    global.crypto = require('node:crypto').webcrypto;
}

const client = new MongoClient(process.env.MONGO_URI);

async function ejecutarConsulta() {
    try {
        await client.connect();
        const dbo = client.db(process.env.MONGO_DB_NAME);
        const coleccion = dbo.collection('eventos');

        // PARAMETROS DE PRUEBA
        const idAgenteDeseado = 1;
        
        const ahora = new Date();
        const fechaDesde = new Date(ahora.getTime() - 10 * 24 * 60 * 60 * 1000);
        const fechaHasta = ahora; // hasta hoy

        console.log(`🔎 Buscando eventos de decisión para el agente ID: ${idAgenteDeseado}...`);

        const pipeline = [
            {
                $match: {
                    "infoAgente.id": idAgenteDeseado,
                    tipoEvento: "decisión",
                    timestamp: {
                        $gte: fechaDesde,
                        $lte: fechaHasta
                    }
                }
            },
            {
                // 2. Ordenamos cronológicamente (1 = De más antiguo a más reciente)
                $sort: {
                    timestamp: 1
                }
            },
            {
                $project: {
                    _id: 0,
                    fecha: "$timestamp",
                    contexto: "$detalles.contextoOperacional",
                    parametros: "$detalles.parametrosEntrada"
                }
            }
        ];

        const resultados = await coleccion.aggregate(pipeline).toArray();

        if (resultados.length === 0) {
            console.log("❌ No se encontraron eventos de decisión en ese rango de fechas para este agente.");
        } else {
            console.log(`\n✅ Se encontraron ${resultados.length} eventos de decisión:`);
            
            const tablaLimpia = resultados.map(r => ({ //si no hacemos esto muestra [Object]
                ...r,
                parametros: JSON.stringify(r.parametros)
            }));

            console.table(tablaLimpia);
        }

    } catch (error) {
        console.error("🔴 Error ejecutando la consulta:", error);
    } finally {
        await client.close();
    }
}

ejecutarConsulta();