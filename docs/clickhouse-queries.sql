-- Consultas Útiles de ClickHouse para Telemetría de Drones

-- ============================================
-- CONSULTAS BÁSICAS
-- ============================================

-- Ver últimos 10 registros
SELECT *
FROM drone_telemetry.telemetry_data
ORDER BY timestamp DESC
LIMIT 10;

-- Contar registros totales
SELECT count() as total_records
FROM drone_telemetry.telemetry_data;

-- Contar registros por drone
SELECT 
    drone_id,
    count() as message_count,
    min(timestamp) as first_seen,
    max(timestamp) as last_seen
FROM drone_telemetry.telemetry_data
GROUP BY drone_id
ORDER BY message_count DESC;

-- ============================================
-- ANÁLISIS DE BATERÍA
-- ============================================

-- Nivel de batería actual por drone
SELECT 
    drone_id,
    argMax(battery_level, timestamp) as current_battery,
    argMax(status, timestamp) as current_status
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 5 MINUTE
GROUP BY drone_id
ORDER BY current_battery ASC;

-- Drones con batería crítica (<20%)
SELECT 
    drone_id,
    battery_level,
    timestamp,
    status
FROM drone_telemetry.telemetry_data
WHERE battery_level < 20
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC;

-- Promedio de descarga de batería por drone
SELECT 
    drone_id,
    avg(battery_level) as avg_battery,
    min(battery_level) as min_battery,
    max(battery_level) as max_battery
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 DAY
GROUP BY drone_id;

-- ============================================
-- ANÁLISIS GEOESPACIAL
-- ============================================

-- Última posición conocida de cada drone
SELECT 
    drone_id,
    argMax(latitude, timestamp) as last_latitude,
    argMax(longitude, timestamp) as last_longitude,
    argMax(altitude, timestamp) as last_altitude,
    max(timestamp) as last_update
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 10 MINUTE
GROUP BY drone_id;

-- Ruta de un drone específico (últimas 100 posiciones)
SELECT 
    timestamp,
    latitude,
    longitude,
    altitude,
    speed
FROM drone_telemetry.telemetry_data
WHERE drone_id = 'DRONE_001'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC
LIMIT 100;

-- Drones en una zona específica (bounding box)
SELECT 
    drone_id,
    latitude,
    longitude,
    timestamp
FROM drone_telemetry.telemetry_data
WHERE latitude BETWEEN 40.40 AND 40.45
  AND longitude BETWEEN -3.75 AND -3.70
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC;

-- ============================================
-- ANÁLISIS DE VELOCIDAD Y ALTITUD
-- ============================================

-- Estadísticas de velocidad por drone
SELECT 
    drone_id,
    avg(speed) as avg_speed,
    max(speed) as max_speed,
    min(speed) as min_speed,
    quantile(0.5)(speed) as median_speed
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 DAY
GROUP BY drone_id;

-- Estadísticas de altitud
SELECT 
    drone_id,
    avg(altitude) as avg_altitude,
    max(altitude) as max_altitude,
    min(altitude) as min_altitude
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 DAY
GROUP BY drone_id;

-- ============================================
-- ANÁLISIS TEMPORAL
-- ============================================

-- Mensajes por minuto (última hora)
SELECT 
    toStartOfMinute(timestamp) as minute,
    count() as messages_per_minute
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 HOUR
GROUP BY minute
ORDER BY minute DESC;

-- Mensajes por hora (últimas 24 horas)
SELECT 
    toStartOfHour(timestamp) as hour,
    count() as messages_per_hour,
    uniq(drone_id) as unique_drones
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY hour
ORDER BY hour DESC;

-- Actividad por drone en los últimos 30 minutos
SELECT 
    drone_id,
    toStartOfInterval(timestamp, INTERVAL 5 MINUTE) as interval,
    count() as message_count,
    avg(battery_level) as avg_battery
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 30 MINUTE
GROUP BY drone_id, interval
ORDER BY drone_id, interval DESC;

-- ============================================
-- ANÁLISIS DE ESTADO
-- ============================================

-- Distribución de estados actuales
SELECT 
    status,
    count(DISTINCT drone_id) as drone_count
FROM (
    SELECT 
        drone_id,
        argMax(status, timestamp) as status
    FROM drone_telemetry.telemetry_data
    WHERE timestamp > now() - INTERVAL 5 MINUTE
    GROUP BY drone_id
)
GROUP BY status;

-- Historial de cambios de estado por drone
SELECT 
    drone_id,
    status,
    count() as occurrences,
    min(timestamp) as first_occurrence,
    max(timestamp) as last_occurrence
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 DAY
GROUP BY drone_id, status
ORDER BY drone_id, last_occurrence DESC;

-- ============================================
-- ANÁLISIS DE MISIONES
-- ============================================

-- Drones por misión activa
SELECT 
    mission_id,
    groupArray(drone_id) as drones,
    count(DISTINCT drone_id) as drone_count,
    avg(battery_level) as avg_battery
FROM (
    SELECT 
        drone_id,
        argMax(mission_id, timestamp) as mission_id,
        argMax(battery_level, timestamp) as battery_level
    FROM drone_telemetry.telemetry_data
    WHERE timestamp > now() - INTERVAL 10 MINUTE
    GROUP BY drone_id
)
GROUP BY mission_id;

-- ============================================
-- DETECCIÓN DE ANOMALÍAS
-- ============================================

-- Drones con pérdida de señal (sin datos en últimos 5 min)
SELECT 
    drone_id,
    max(timestamp) as last_seen,
    now() - max(timestamp) as time_since_last_update
FROM drone_telemetry.telemetry_data
GROUP BY drone_id
HAVING time_since_last_update > INTERVAL 5 MINUTE
ORDER BY time_since_last_update DESC;

-- Cambios bruscos de altitud (>50m en 15s)
SELECT 
    t1.drone_id,
    t1.timestamp,
    t1.altitude as altitude_before,
    t2.altitude as altitude_after,
    abs(t2.altitude - t1.altitude) as altitude_change
FROM drone_telemetry.telemetry_data t1
JOIN drone_telemetry.telemetry_data t2 
    ON t1.drone_id = t2.drone_id
WHERE t2.timestamp = t1.timestamp + INTERVAL 15 SECOND
  AND abs(t2.altitude - t1.altitude) > 50
  AND t1.timestamp > now() - INTERVAL 1 HOUR
ORDER BY altitude_change DESC;

-- Temperatura anómala
SELECT 
    drone_id,
    timestamp,
    temperature,
    avg(temperature) OVER (PARTITION BY drone_id) as avg_temp
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 HOUR
  AND abs(temperature - avg(temperature) OVER (PARTITION BY drone_id)) > 10
ORDER BY timestamp DESC;

-- ============================================
-- OPTIMIZACIÓN Y MANTENIMIENTO
-- ============================================

-- Tamaño de la tabla
SELECT 
    database,
    table,
    formatReadableSize(sum(bytes)) as size,
    sum(rows) as rows,
    max(modification_time) as latest_modification
FROM system.parts
WHERE database = 'drone_telemetry'
  AND table = 'telemetry_data'
  AND active
GROUP BY database, table;

-- Particiones de la tabla
SELECT 
    partition,
    sum(rows) as rows,
    formatReadableSize(sum(bytes)) as size
FROM system.parts
WHERE database = 'drone_telemetry'
  AND table = 'telemetry_data'
  AND active
GROUP BY partition
ORDER BY partition DESC;

-- Optimizar tabla (merge parts)
OPTIMIZE TABLE drone_telemetry.telemetry_data FINAL;

-- ============================================
-- EXPORTAR DATOS
-- ============================================

-- Exportar a CSV (ejecutar desde línea de comandos)
-- clickhouse-client --query="SELECT * FROM drone_telemetry.telemetry_data WHERE timestamp > now() - INTERVAL 1 DAY" --format CSV > export.csv

-- Exportar a JSON
-- clickhouse-client --query="SELECT * FROM drone_telemetry.telemetry_data LIMIT 100" --format JSONEachRow > export.json

-- ============================================
-- DASHBOARDS Y MÉTRICAS
-- ============================================

-- Métricas en tiempo real para dashboard
SELECT 
    count(DISTINCT drone_id) as active_drones,
    count() as total_messages,
    avg(battery_level) as avg_battery,
    avg(speed) as avg_speed,
    avg(altitude) as avg_altitude,
    avg(temperature) as avg_temperature
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 MINUTE;

-- KPIs por drone para dashboard
SELECT 
    drone_id,
    argMax(latitude, timestamp) as lat,
    argMax(longitude, timestamp) as lon,
    argMax(altitude, timestamp) as alt,
    argMax(battery_level, timestamp) as battery,
    argMax(speed, timestamp) as speed,
    argMax(temperature, timestamp) as temp,
    argMax(status, timestamp) as status,
    count() as messages_last_hour
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 HOUR
GROUP BY drone_id;
