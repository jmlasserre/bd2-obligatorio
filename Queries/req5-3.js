require('dotenv').config();
const { MongoClient } = require('mongodb');

const client = new MongoClient(process.env.MONGO_URI);

async function ejecutarConsulta() {
    try {
        await client.connect();
        const dbo = client.db(process.env.MONGO_DB_NAME);
        const coleccion = dbo.collection('eventos');

        // PARÁMETROS DE PRUEBA
        const idAgenteDeseado = parseInt(process.env.ID_AGENTE_DESEADO_5_3); 
        const horaInicio = parseInt(process.env.HORA_INICIO);
        const horaFin = parseInt(process.env.HORA_FIN);

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