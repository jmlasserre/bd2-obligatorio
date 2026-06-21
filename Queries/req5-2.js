const config = require('../config');
const { MongoClient } = require('mongodb');

const client = new MongoClient(config.mongo.uri);

async function ejecutarConsulta()
{
    try
    {
        await client.connect();
        const dbo = client.db(config.mongo.dbName);

        const fechaDesde = new Date();
        fechaDesde.setDate(fechaDesde.getDate() - 7);

        const resultado = await dbo.collection(config.mongo.colecciones.eventos).aggregate([
            {
                $match: 
                {
                    timestamp: 
                    {
                        $gte: fechaDesde //Greater Than
                    }
                }
            },

            {
                $group:
                {
                    _id: "$infoAgente.id",
                    nombreAgente:
                    {
                        $first: "$infoAgente.nombre"
                    },
                    
                    totalEventos:
                    {
                        $sum: 1 
                    },

                    eventosAlta:
                    {
                        $sum:
                        {
                            $cond:
                            [
                                {$eq: ["$criticidad", "alta"]}, 1, 0
                            ]
                        }
                    }
                }
            },

            {
                $addFields:
                {
                    proporcion:
                    {
                        $cond: 
                        [
                            {$gt: ["$totalEventos", 0]},
                            {$divide: ["$eventosAlta", "$totalEventos"]},
                            0
                        ]
                        
                    }
                }
            },

            {
                $sort:
                {
                    eventosAlta: -1 //Desc
                }
            },

            {
                $limit: 5
            },

            {
                $project:
                {
                    _id: 0,
                    idAgente: "$_id",
                    nombreAgente: 1,
                    eventosAlta: 1,
                    totalEventos: 1,
                    proporcion: { $round: [ "$proporcion", 2 ] }
                }
            }
        ]).toArray();

        console.table(resultado);
    }
    catch(err)
    {
        console.error("Error al ejecutar la consulta:", err); 
    }
    finally
    {
        await client.close();
    }

}

ejecutarConsulta();