const express = require('express');
const { Pool } = require('pg');
const client = require('prom-client');

const app = express();
const port = 3000;

// ==========================================
// 1. FUNCIÓN HELPER PARA LOGS EN JSON (DevOps)
// ==========================================
function logEvent(level, message, metadata = {}) {
  const logEntry = {
    timestamp: new Date().toISOString(),
    level, // INFO, WARN, ERROR
    service: 'backend',
    message,
    ...metadata
  };
  // Imprime JSON en stdout para que Promtail/Loki lo lean fácilmente
  console.log(JSON.stringify(logEntry));
}

// ==========================================
// 2. MIDDLEWARE DE REGISTRO DE PETICIONES HTTP
// ==========================================
app.use((req, res, next) => {
  const start = Date.now();
  
  // Escuchar cuando finalice la respuesta para calcular tiempo y status code
  res.on('finish', () => {
    const duration = Date.now() - start;
    const level = res.statusCode >= 500 ? 'ERROR' : res.statusCode >= 400 ? 'WARN' : 'INFO';

    logEvent(level, `HTTP ${req.method} ${req.url}`, {
      method: req.method,
      url: req.originalUrl,
      status: res.statusCode,
      durationMs: duration,
      ip: req.ip
    });
  });

  next();
});

// Colección de métricas por defecto de Prometheus
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

// Endpoint /metrics exclusivo para Prometheus
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', client.register.contentType);
  res.end(await client.register.metrics());
});

// CORS
app.use((req, res, next) => {
  res.header("Access-Control-Allow-Origin", "*");
  next();
});

// Conexión DB
// Evalúa si se debe activar SSL según la variable de entorno
const useSsl = process.env.DB_SSL === 'true';
const pool = new Pool({
  user: process.env.DB_USER,
  host: process.env.DB_HOST,
  database: process.env.DB_NAME,
  password: process.env.DB_PASSWORD,
  port: process.env.POSTGRES_PORT,
  ssl: useSsl ? { rejectUnauthorized: false } : false // Soporte TLS para PostgreSQL Flexible Server
});

// ==========================================
// 3. INICIALIZACIÓN DE LA BASE DE DATOS (Auto-migración)
// ==========================================
async function initDb() {
  const initSql = `
    CREATE TABLE IF NOT EXISTS cuadros (
        id SERIAL PRIMARY KEY,
        nombre VARCHAR(100),
        autor VARCHAR(100),
        anio INT
    );

    INSERT INTO cuadros (id, nombre, autor, anio) VALUES 
    (1, 'Mona Lisa', 'Leonardo da Vinci', 1503),
    (2, 'La Noche Estrellada', 'Vincent van Gogh', 1889),
    (3, 'El grito', 'Edvard Munch', 1893)
    ON CONFLICT (id) DO NOTHING;
  `;

  try {
    logEvent('INFO', 'Iniciando verificación/creación de tablas en PostgreSQL...');
    await pool.query(initSql);
    logEvent('INFO', 'Tabla "cuadros" e inserts iniciales verificados con éxito.');
  } catch (err) {
    logEvent('ERROR', 'Error crítico durante la inicialización de la base de datos', { error: err.message });
    throw err; // Lanza el error para prevenir levantar el servidor Express
  }
}

// Endpoint Pintura
app.get('/pintura/:id', async (req, res) => {
  const { id } = req.params;
  try {
    const result = await pool.query('SELECT * FROM cuadros WHERE id = $1', [id]);
    if (result.rows.length > 0) {
      res.json(result.rows[0]);
    } else {
      // Registrar advertencia de negocio
      logEvent('WARN', `Intento de acceso a cuadro inexistente ID: ${id}`, { id });
      res.status(404).json({ error: "Cuadro no encontrado" });
    }
  } catch (err) {
    // Registrar error grave de base de datos o consulta
    logEvent('ERROR', `Error al consultar la base de datos para cuadro ID: ${id}`, { error: err.message });
    res.status(500).json({ error: err.message });
  }
});

// Endpoint Healthcheck
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.status(200).json({ status: 'UP', database: 'CONNECTED' });
  } catch (err) {
    logEvent('ERROR', 'Healthcheck falló: Base de datos no disponible', { error: err.message });
    res.status(500).json({ status: 'DOWN', error: err.message });
  }
});

// ==========================================
// 4. ARRANQUE DEL SERVIDOR (Async Start)
// ==========================================
async function startServer() {
  try {
    // 1. Ejecutar las migraciones DDL/DML primero
    await initDb();

    // 2. Levantar el servidor HTTP una vez asegurada la BD
    app.listen(port, () => {
      logEvent('INFO', `Backend corriendo en http://localhost:${port}`, { port });
    });
  } catch (err) {
    logEvent('ERROR', 'No se pudo iniciar el servicio Backend debido a fallas en la base de datos', { error: err.message });
    process.exit(1); // Detiene la ejecución para reiniciar la réplica en ACA
  }
}

startServer();