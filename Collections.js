//Collection
db.createCollection("eventos", 
{
    validator: 
    {
        $jsonSchema:
        {
            bsonType: "object",
            required: ["idEvento", "idAgente", "tipoEvento","criticidad", "timestamp", "infoAgente"],
            properties: 
            {
                idEvento: 
                {
                    bsonType: "int",
                    description: "Id del evento."
                },


                idAgente: 
                {
                    bsonType: "int",
                    description: "Id del agente que generó el evento."
                },


                tipoEvento: 
                {
                    bsonType: "string",
                    description: "Categoria del evento."
                },

                criticidad: 
                {
                    bsonType: "string",
                    enum: ["alta", "media", "baja"],
                    description: "Criticidad"
                },

                timestamp: //Requerido para ejercicios de mas adelante
                {
                    bsonType: "date",
                    description: "Fecha y hora donde se dio el evento"
                },

                infoAgente:
                {
                    bsonType: "object",
                    description: "Informacion de responsabilidad necesaria",
                    required: ["nombre", "tipo", "emailAdmin"],
                    properties:
                    {
                        nombre: {bsonType: "string"},
                        tipo: {bsonType: "string"},
                        emailAdmin: {bsonType: "string"}
                    }
                
                },

                detalles: 
                {
                    bsonType: "object"
                }

            }

        }
    }
})