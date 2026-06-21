# bd2-obligatorio

Obligatorio para Bases de Datos 2

## Parte 5

## Cargar datos de prueba

1. Configurar los parámetros del `config.js` según la configuración deseada.
2. Crear la colección `eventos` en la base de datos de MongoDB especificada.
3. Ejecutar el comando `npm run loadTests`.

## Ejecutar consultas

Creamos comandos para ejecutar fácilmente las consultas de la Parte 5. Los parámetros a utilizar para cada una se deben configurar en `config,js`.

```raw

# Parámetros para consultas

## Consulta 5.1
ID_AGENTE_DESEADO_5_1=1
FECHA_DESDE=2025-01-12T01:30:00 # ¡mantener ese formato para no romper la consulta!
FECHA_HASTA=2026-06-20T15:30:00 # lo mismo acá

## Consulta 5.3
ID_AGENTE_DESEADO_5_3=2
HORA_INICIO=0 # 0-23
HORA_FIN=23 # 0-23

```

A continuación, los comandos para cada consulta:

| Consulta | Comando          |
| ---      | ---              |
| 5.1      | `npm run query1` |
| 5.2.     | `npm run query2` |
| 5.3      | `npm run query2` |

## Checklist

- [x] Parte 1
- [x] Parte 2
- [ ] Parte 3 (en progreso)
- [ ] Parte 4 (en progreso)
- [ ] Parte 5
- [ ] Parte 6

## TODO

Acá pongan todo lo demás que falte hacer.

- [X] Parte 2: Cambiar `RAISE_APPLICATION_ERROR` por excepciones; la rúbrica recomienda.
- [X] Parte 2: Contemplar casos de "mutación de tablas".
- [X] Parte 2: Arreglar procedures. Varios no compilan.
- [X] Parte 4: Arreglar `Collections.js`. Actualizarlo para usar una única collection en vez de dos.
- [X] Parte 4: Arreglar `integration.js` para trabajar con una única collection.