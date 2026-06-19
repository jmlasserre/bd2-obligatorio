#!/usr/bin/node

const {MongoClient} = require('mongodb');

if (typeof global.crypto === 'undefined') 
{
    global.crypto = require('node:crypto').webcrypto;
}

const client = new MongoClient(process.env.MONGO_URI);

async function ejecutarConsulta()
{
    try
    {
        await client.connect();
        const dbo = client.db(process.env.MONGO_DB_NAME);

        const fechaDesde = new Date();
        fechaDesde.setDate(fechaDesde.getDate() - 7);

        const resultado = await dbo.collection(process.env.COL_EVENTOS).aggregate([
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
                    _id: "$idAgente",
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
                    proporcion: 1
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