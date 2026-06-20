require("dotenv").config();
const { MongoClient } = require("mongodb");

const MONGO_URI = process.env.MONGO_URI;
const DB_NAME = process.env.MONGO_DB_NAME;

if (!MONGO_URI || !DB_NAME) {
    console.error("Faltan variables de entorno. Verificá que tu .env tenga MONGO_URI y DB_NAME definidos.");
    process.exit(1);
}

const ahora = new Date();

const AGENTES = {
    1: { nombre: "Hazel_OC",     tipo: "Generador de contenido" },
    2: { nombre: "sirclawat",    tipo: "Generador de contenido" },
    3: { nombre: "cerebro_biz",  tipo: "Moderador" },
    4: { nombre: "ModBot_Prime", tipo: "Moderador" },
    5: { nombre: "Smee",         tipo: "Observador" }
};

function infoAgenteDe(id) {
    return { id: id, nombre: AGENTES[id].nombre, tipo: AGENTES[id].tipo };
}

function hace({ dias = 0, horas = 0, minutos = 0 } = {}) {
    return new Date(ahora.getTime()
        - dias * 24 * 60 * 60 * 1000
        - horas * 60 * 60 * 1000
        - minutos * 60 * 1000);
}

function hoyALaHora(hora, minutos = 0) {
    const d = new Date(ahora);
    d.setHours(hora, minutos, 0, 0);
    return d;
}

function construirEventos() {
    return [
        // ====================================================================
        // BLOQUE 1 — Eventos tipo "decisión" del Agente 1 (para Req 5.1)
        // ====================================================================
        {
            tipoEvento: "decisión",
            criticidad: "media",
            timestamp: hace({ dias: 1, horas: 2 }),
            infoAgente: infoAgenteDe(1),
            detalles: {
                contextoOperacional: "Generación de respuesta a comentario en m/philosophy",
                parametrosEntrada: { temperatura: 0.7, modeloUsado: "gpt-x", maxTokens: 500 }
            }
        },
        {
            tipoEvento: "decisión",
            criticidad: "alta",
            timestamp: hace({ dias: 3, horas: 5 }),
            infoAgente: infoAgenteDe(1),
            detalles: {
                contextoOperacional: "Evaluación de publicación candidata a cita en m/security",
                parametrosEntrada: { temperatura: 0.5, modeloUsado: "gpt-x", maxTokens: 300 }
            }
        },
        {
            tipoEvento: "decisión",
            criticidad: "baja",
            timestamp: hace({ dias: 6 }),
            infoAgente: infoAgenteDe(1),
            detalles: {
                contextoOperacional: "Selección de etiquetas temáticas para publicación en m/builds",
                parametrosEntrada: { temperatura: 0.3, modeloUsado: "gpt-x-mini", maxTokens: 150 }
            }
        },
        {
            // Evento FUERA del rango típico de prueba (hace 20 días) para validar
            // que el filtro por fecha del Req 5.1 lo excluya correctamente
            tipoEvento: "decisión",
            criticidad: "media",
            timestamp: hace({ dias: 20 }),
            infoAgente: infoAgenteDe(1),
            detalles: {
                contextoOperacional: "Decisión de comentar en hilo de m/consciousness",
                parametrosEntrada: { temperatura: 0.6, modeloUsado: "gpt-x", maxTokens: 400 }
            }
        },
        // Evento de otro agente con mismo tipoEvento, para confirmar que el
        // filtro por agente del Req 5.1 no mezcla resultados
        {
            tipoEvento: "decisión",
            criticidad: "alta",
            timestamp: hace({ dias: 2 }),
            infoAgente: infoAgenteDe(2),
            detalles: {
                contextoOperacional: "Evaluación de contenido reportado en m/crypto",
                parametrosEntrada: { temperatura: 0.4, modeloUsado: "gpt-x", maxTokens: 250 }
            }
        },

        // ====================================================================
        // BLOQUE 2 — Eventos de criticidad variada, últimos 7 días (Req 5.2)
        //   Agente 1: 1 alta / 2 total  -> 40%
        //   Agente 2: 3 alta / 5 total  -> 66.7%
        //   Agente 3: 1 alta / 4 total  -> 25%
        //   Agente 4: 3 alta / 3 total  -> 100%
        //   Agente 5: 0 alta / 3 total  -> 0%
        // ====================================================================
        { tipoEvento: "interacción con usuario", criticidad: "alta",  timestamp: hace({ dias: 1 }), infoAgente: infoAgenteDe(1), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 4501 } },
        { tipoEvento: "interacción con usuario", criticidad: "baja",  timestamp: hace({ dias: 4 }), infoAgente: infoAgenteDe(1), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 4502 } },

        { tipoEvento: "error",                    criticidad: "alta",  timestamp: hace({ dias: 1, horas: 3 }), infoAgente: infoAgenteDe(2), detalles: { codigoError: "TIMEOUT", mensaje: "Excedido tiempo de respuesta al generar comentario" } },
        { tipoEvento: "acceso no controlado",     criticidad: "alta",  timestamp: hace({ dias: 5 }),            infoAgente: infoAgenteDe(2), detalles: { recursoSolicitado: "/admin/config", resultado: "denegado" } },
        { tipoEvento: "interacción con usuario",  criticidad: "alta",  timestamp: hace({ dias: 2, horas: 4 }),  infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "publicacion_creada", idContenidoRelacionado: 4503 } },
        { tipoEvento: "métrica de ejecución",     criticidad: "baja",  timestamp: hace({ dias: 6 }),            infoAgente: infoAgenteDe(2), detalles: { tiempoRespuestaMs: 220, tokensUtilizados: 180 } },
        { tipoEvento: "interacción con usuario",  criticidad: "media", timestamp: hace({ dias: 3 }),            infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 4504 } },

        { tipoEvento: "error",                    criticidad: "alta",  timestamp: hace({ dias: 2 }), infoAgente: infoAgenteDe(3), detalles: { codigoError: "RATE_LIMIT", mensaje: "Límite de publicaciones por hora alcanzado" } },
        { tipoEvento: "interacción con usuario",  criticidad: "media", timestamp: hace({ dias: 1 }), infoAgente: infoAgenteDe(3), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 4505 } },
        { tipoEvento: "interacción con usuario",  criticidad: "baja",  timestamp: hace({ dias: 4 }), infoAgente: infoAgenteDe(3), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 4506 } },
        { tipoEvento: "métrica de ejecución",     criticidad: "media", timestamp: hace({ dias: 5 }), infoAgente: infoAgenteDe(3), detalles: { tiempoRespuestaMs: 340, tokensUtilizados: 512 } },

        { tipoEvento: "acceso no controlado",     criticidad: "alta",  timestamp: hace({ dias: 1 }), infoAgente: infoAgenteDe(4), detalles: { recursoSolicitado: "/internal/logs", resultado: "denegado" } },
        { tipoEvento: "error",                    criticidad: "alta",  timestamp: hace({ dias: 3 }), infoAgente: infoAgenteDe(4), detalles: { codigoError: "AUTH_FAIL", mensaje: "Token de sesión inválido" } },
        { tipoEvento: "acceso no controlado",     criticidad: "alta",  timestamp: hace({ dias: 6 }), infoAgente: infoAgenteDe(4), detalles: { recursoSolicitado: "/admin/users", resultado: "denegado" } },

        { tipoEvento: "interacción con usuario",  criticidad: "baja",  timestamp: hace({ dias: 1 }), infoAgente: infoAgenteDe(5), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 4507 } },
        { tipoEvento: "interacción con usuario",  criticidad: "media", timestamp: hace({ dias: 2 }), infoAgente: infoAgenteDe(5), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 4508 } },
        { tipoEvento: "métrica de ejecución",     criticidad: "baja",  timestamp: hace({ dias: 3 }), infoAgente: infoAgenteDe(5), detalles: { tiempoRespuestaMs: 150, tokensUtilizados: 90 } },

        // Eventos "alta" FUERA de la última semana, para validar el filtro de fecha
        { tipoEvento: "error", criticidad: "alta", timestamp: hace({ dias: 12 }), infoAgente: infoAgenteDe(1), detalles: { codigoError: "TIMEOUT", mensaje: "Evento antiguo, no debe contar" } },
        { tipoEvento: "error", criticidad: "alta", timestamp: hace({ dias: 15 }), infoAgente: infoAgenteDe(5), detalles: { codigoError: "TIMEOUT", mensaje: "Evento antiguo, no debe contar" } },

        // ====================================================================
        // BLOQUE 3 — Eventos "interacción con usuario" del Agente 2 (Req 5.3)
        // Franja horaria de prueba: 8 a 17 horas, día de hoy
        // ====================================================================
        { tipoEvento: "interacción con usuario", criticidad: "baja",  timestamp: hoyALaHora(8, 15),  infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 5001 } },

        { tipoEvento: "interacción con usuario", criticidad: "media", timestamp: hoyALaHora(10, 5),  infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 5002 } },
        { tipoEvento: "interacción con usuario", criticidad: "baja",  timestamp: hoyALaHora(10, 22), infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 5003 } },
        { tipoEvento: "interacción con usuario", criticidad: "baja",  timestamp: hoyALaHora(10, 47), infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 5004 } },

        { tipoEvento: "interacción con usuario", criticidad: "media", timestamp: hoyALaHora(14, 10), infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "publicacion_creada", idContenidoRelacionado: 5005 } },
        { tipoEvento: "interacción con usuario", criticidad: "baja",  timestamp: hoyALaHora(14, 50), infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 5006 } },

        { tipoEvento: "interacción con usuario", criticidad: "alta",  timestamp: hoyALaHora(17, 0),  infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "comentario_creado", idContenidoRelacionado: 5007 } },

        // Fuera de la franja 8-17h -> NO deben aparecer en el resultado del Req 5.3
        { tipoEvento: "interacción con usuario", criticidad: "baja", timestamp: hoyALaHora(7, 30), infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 5008 } },
        { tipoEvento: "interacción con usuario", criticidad: "baja", timestamp: hoyALaHora(19, 0), infoAgente: infoAgenteDe(2), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 5009 } },

        // Mismo tipo de evento pero de OTRO agente, para confirmar que el
        // filtro por agente del Req 5.3 no mezcla resultados
        { tipoEvento: "interacción con usuario", criticidad: "media", timestamp: hoyALaHora(10, 0), infoAgente: infoAgenteDe(3), detalles: { accionRealizada: "voto_emitido", idContenidoRelacionado: 5010 } },

        // ====================================================================
        // BLOQUE 4 — Eventos variados adicionales (volumen / realismo)
        // ====================================================================
        { tipoEvento: "creación",             criticidad: "baja",  timestamp: hace({ dias: 8 }),  infoAgente: infoAgenteDe(3), detalles: { tipoContenido: "publicación", idComunidad: 7 } },
        { tipoEvento: "creación",             criticidad: "baja",  timestamp: hace({ dias: 9 }),  infoAgente: infoAgenteDe(4), detalles: { tipoContenido: "comentario", idComunidad: 2 } },
        { tipoEvento: "métrica de ejecución", criticidad: "media", timestamp: hace({ dias: 11 }), infoAgente: infoAgenteDe(5), detalles: { tiempoRespuestaMs: 410, tokensUtilizados: 670 } },
        { tipoEvento: "decisión",             criticidad: "baja",  timestamp: hace({ dias: 14 }), infoAgente: infoAgenteDe(3), detalles: { contextoOperacional: "Selección de hilo a responder en m/agents", parametrosEntrada: { temperatura: 0.6, modeloUsado: "gpt-x", maxTokens: 350 } } },
        { tipoEvento: "error",                criticidad: "media", timestamp: hace({ dias: 16 }), infoAgente: infoAgenteDe(1), detalles: { codigoError: "PARSE_ERROR", mensaje: "Formato de respuesta inválido" } }
    ];
}

async function main() {
    const client = new MongoClient(MONGO_URI);

    try {
        await client.connect();
        console.log("Conectado a MongoDB.");

        const db = client.db(DB_NAME);
        const coleccion = db.collection("eventos");

        const eventos = construirEventos();
        const resultado = await coleccion.insertMany(eventos);

        console.log(`Documentos insertados: ${resultado.insertedCount}`);
        console.log(`Total de documentos en la colección "eventos": ${await coleccion.countDocuments({})}`);
    } catch (error) {
        console.error("Error al insertar los datos de prueba:", error);
        process.exitCode = 1;
    } finally {
        await client.close();
        console.log("Conexión cerrada.");
    }
}

main();