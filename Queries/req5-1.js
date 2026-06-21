require('dotenv').config();
const { MongoClient } = require('mongodb');

const client = new MongoClient(process.env.MONGO_URI);

async function ejecutarConsulta() {
    try {
        await client.connect();
        const dbo = client.db(process.env.MONGO_DB_NAME);
        const coleccion = dbo.collection('eventos');

        // PARAMETROS DE PRUEBA
        const idAgenteDeseado = parseInt(process.env.ID_AGENTE_DESEADO_5_1);
        
        const fechaDesde = new Date(process.env.FECHA_DESDE);
        if (isNaN(fechaDesde.getTime())) {
            throw new Error("FECHA_DESDE en el .env no es una fecha válida");
        }
        const fechaHasta = new Date(process.env.FECHA_HASTA);
        if (isNaN(fechaHasta.getTime())) {
            throw new Error("FECHA_HASTA en el .env no es una fecha válida");
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