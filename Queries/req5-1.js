const config = require('../config');
const { MongoClient } = require('mongodb');

const client = new MongoClient(config.mongo.uri);

async function ejecutarConsulta() {
    try {
        await client.connect();
        const dbo = client.db(config.mongo.dbName);
        const coleccion = dbo.collection(config.mongo.colecciones.eventos);

        // PARAMETROS DE PRUEBA
        const idAgenteDeseado = config.consultas["5_1"].idAgenteDeseado;

        const fechaDesde = new Date(config.consultas["5_1"].fechaDesde);
        if (isNaN(fechaDesde.getTime())) {
            throw new Error("fechaDesde en config.js no es una fecha válida");
        }
        const fechaHasta = new Date(config.consultas["5_1"].fechaHasta);
        if (isNaN(fechaHasta.getTime())) {
            throw new Error("fechaHasta en config.js no es una fecha válida");
        }

        console.log(`Buscando eventos de decisión para el agente ID: ${idAgenteDeseado}...`);

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
            console.log("No se encontraron eventos de decisión en ese rango de fechas para este agente.");
        } else {
            console.log(`\n Se encontraron ${resultados.length} eventos de decisión: `);

            const tablaLimpia = resultados.map(r => ({ //si no hacemos esto muestra [Object]
                ...r,
                parametros: JSON.stringify(r.parametros)
            }));

            console.table(tablaLimpia);
        }

    } catch (error) {
        console.error("Error ejecutando la consulta: ", error);
    } finally {
        await client.close();
    }
}

ejecutarConsulta();