# Script de integración Oracle - MongoDB

## ¿Cómo usarlo?

1. Crear las colecciones `agentes_perfil` y `eventos` según se especifica en `Collections.js`.
1. Crear un archivo `.env` en la misma carpeta que `integration.js`.
2. Dentro del archivo, pegar lo siguiente:

```markdown
# Oracle DB
ORACLE_USER=tu_usuario_oracle
ORACLE_PASSWORD=tu_password_oracle
ORACLE_CONNECT_STRING=localhost:1521/XEPDB1

# MongoDB
MONGO_URI=mongodb://localhost:27017
MONGO_DB_NAME=tu_base_de_datos_mongo

# Colecciones (Opcional, por si cambian de nombre)
COL_AGENTES=agentes_perfil
COL_EVENTOS=eventos
```

3. Editar los campos según la configuración deseada.
4. Correr `integration.js` con `npm start` o `node integration.js`.