db.createCollection("agentes_perfil", //Util para consultas de mas adelante en el ejercicio
    {
        validator:
        {
            $jsonSchema:
            {
                bsonType: "object",
                required: ["idAgente", "nombre", "tipo", "estado", "configuracion", "emailAdmin", "fechaCreacion"],

                properties:
                {
                    idAgente:
                    {
                        bsonType: "int",
                        description: "Identificador del agente"
                    },

                    nombre:
                    {
                        bsonType: "string",
                        description: "Nombre del agente"
                    },

                    tipo: 
                    {
                        bsonType: "string",
                        enum : ["Generador de contenido", "Moderador", "Observador"],
                        description: "Tipo de agente"
                    },

                    estado:
                    {
                        bsonType: "string",
                        enum: ["Activo", "Suspendido"],
                        description: "Estado actual del agente"
                    },

                    configuracion:
                    {
                        bsonType: "string",
                        enum: ["Simple", "Compuesta"],
                        description: "Configuracion activa del agente"
                    },

                    emailAdmin:
                    {
                        bsonType: "string",
                        description: "Email del humano"
                    },

                    fechaCreacion:
                    {
                        bsonType: "date",
                        description: "Fecha de creacion del agente"
                    },

                    descripcion:
                    {
                        bsonType: "string",
                        description: "Descripcion del proposito del agente"
                    },

                    prompt:
                    {
                        bsonType: "string",
                        description: "Instrucciones del agente."
                    },

                    historialConfiguraciones:
                    {
                        bsonType: "array",
                        description: "Historial de configuraciones del agente",
                        items: 
                        {
                            bsonType: "object",
                            required: ["version", "fechaAplicacion"],
                            properties: 
                            {
                                version: { bsonType: "string" },
                                fechaAplicacion: { bsonType: "date" },
                                descripcion: { bsonType: "string" }
                            }
                        }
                    },

                    comunidades:
                    {
                        bsonType: "array",
                        description: "Lista de comunidades a las que pertenece el agente",
                        items:
                        {
                            bsonType: "object",
                            required: ["idComunidad", "participacion"],
                            properties: 
                            {
                                idComunidad: { bsonType: "int" },
                                nombre: { bsonType: "string" },
                                participacion: 
                                {
                                    bsonType: "string",
                                    enum: ["Seguidor", "Miembro activo"]
                                }
                            }
                        }
                    },
                }
            }
        }
    }
)

//Collection 2
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