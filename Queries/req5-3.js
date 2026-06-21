const config = require('../config');
const { MongoClient } = require('mongodb');

const client = new MongoClient(config.mongo.uri);

async function ejecutarConsulta() {
    try {
        await client.connect();
        const dbo = client.db(config.mongo.dbName);
        const coleccion = dbo.collection(config.mongo.colecciones.eventos);

        // PARÁMETROS DE PRUEBA
        const idAgenteDeseado = config.consultas["5_3"].idAgenteDeseado;
        const horaInicio = config.consultas["5_3"].horaInicio;
        const horaFin = config.consultas["5_3"].horaFin;

        console.log(`Buscando interacciones del agente ${idAgenteDeseado} entre las ${horaInicio}:00 y las ${horaFin}:00...`);

        const pipeline = [
            {
                $match: {
                    "infoAgente.id": idAgenteDeseado,
                    tipoEvento: "interacción con usuario",
                    $expr: { // para que nos deje hacer funciones
                        $and: [
                            { $gte: [{ $hour: "$timestamp" }, horaInicio] }, // greater than or equal
                            { $lte: [{ $hour: "$timestamp" }, horaFin] } // less than o equal
                        ]
                    }
                }
            },
            {
                $group: {
                    _id: { $hour: "$timestamp" },
                    cantidadInteracciones: { $sum: 1 }
                }
            },
            {
                $sort: {
                    "_id": 1
                }
            },
            {
                $project: {
                    _id: 0,
                    hora: "$_id",
                    cantidadInteracciones: 1
                }
            }
        ];

        const resultados = await coleccion.aggregate(pipeline).toArray();

        if (resultados.length === 0) {
            console.log("No se encontraron interacciones en esa franja horaria para este agente.");
        } else {
            console.log(`\n Resumen de interacciones por hora: `);
            console.table(resultados);
        }

    } catch (error) {
        console.error("Error ejecutando la consulta 5.3: ", error);
    } finally {
        await client.close();
    }
}

ejecutarConsulta();