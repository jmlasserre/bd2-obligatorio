db.createCollection("eventos", 
{
    validator: 
    {
        $jsonSchema:
        {
            bsonType: "object",
            required: ["tipoEvento", "criticidad", "timestamp", "infoAgente"],
            properties: 
            {
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

                timestamp:
                {
                    bsonType: "date",
                    description: "Fecha y hora donde se dio el evento"
                },

                infoAgente:
                {
                    bsonType: "object",
                    description: "Informacion de responsabilidad necesaria",
                    required: ["id", "nombre", "tipo"],
                    properties:
                    {
                        id: {bsonType: "int", minimum: 1},
                        nombre: {bsonType: "string"},
                        tipo: {bsonType: "string", enum: ['Generador de contenido', 'Moderador', 'Observador']},
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