# Ejemplos de Uso del Sistema

Este documento contiene ejemplos prácticos para interactuar con el sistema de telemetría de drones.

## Tabla de Contenidos

1. [Despliegue Inicial](#despliegue-inicial)
2. [Gestión de Drones](#gestión-de-drones)
3. [Consultas en ClickHouse](#consultas-en-clickhouse)
4. [Monitoreo con Grafana](#monitoreo-con-grafana)
5. [Debugging y Troubleshooting](#debugging-y-troubleshooting)

---

## Despliegue Inicial

### Opción 1: Usando Makefile (Recomendado)

```bash
# Ver todas las opciones disponibles
make help

# Desplegar todo el sistema
make deploy

# Verificar el despliegue
make verify

# Ver información de acceso
make info
```

### Opción 2: Usando Ansible directamente

```bash
# Despliegue completo
ansible-playbook -i inventory/hosts.yml site.yml

# Despliegue solo de ciertos componentes
ansible-playbook -i inventory/hosts.yml site.yml --tags "clickhouse,kafka"

# Modo verbose para debugging
ansible-playbook -i inventory/hosts.yml site.yml -vvv
```

### Opción 3: Despliegue por partes

```bash
# 1. Prerequisitos
make deploy-common

# 2. Base de datos
make deploy-clickhouse

# 3. Mensajería
make deploy-kafka

# 4. Plataforma IoT
make deploy-thingsboard

# 5. Monitoreo
make deploy-monitoring

# 6. Simulador
make deploy-simulator
```

---

## Gestión de Drones

### Provisionar Drones en ThingsBoard

```bash
# Opción 1: Usando make
make provision-devices

# Opción 2: Directamente
python3 /opt/drone-telemetry/drone-simulator/provision_devices.py
```

### Iniciar Simulación

```bash
# Opción 1: Todos los drones (usando make)
make start-drones

# Opción 2: Manualmente
/opt/drone-telemetry/drone-simulator/start_drones.sh

# Opción 3: Un solo dron específico
python3 /opt/drone-telemetry/drone-simulator/drone_simulator.py \
    --drone-id DRONE_001 \
    --host localhost \
    --port 1883 \
    --interval 15
```

### Como Servicio systemd

```bash
# Habilitar e iniciar
sudo systemctl enable drone-simulator
sudo systemctl start drone-simulator

# Ver estado
sudo systemctl status drone-simulator

# Ver logs en tiempo real
sudo journalctl -u drone-simulator -f

# Detener
sudo systemctl stop drone-simulator
```

### Enviar Telemetría Manual (Testing)

```bash
# Usando curl a ThingsBoard
curl -X POST http://localhost:8080/api/v1/YOUR_DEVICE_TOKEN/telemetry \
  -H "Content-Type: application/json" \
  -d '{
    "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%S.000Z)'",
    "latitude": 40.4168,
    "longitude": -3.7038,
    "altitude": 120.5,
    "battery_level": 85.3,
    "speed": 25.8,
    "temperature": 22.4,
    "status": "ACTIVE",
    "mission_id": "TEST_001"
  }'
```

---

## Consultas en ClickHouse

### Acceso a ClickHouse

```bash
# Opción 1: Cliente interactivo
make shell-clickhouse

# Opción 2: Directamente
docker exec -it clickhouse clickhouse-client

# Opción 3: Con credenciales específicas
docker exec clickhouse clickhouse-client \
    --user droneuser \
    --password ClickHouse2025! \
    --database drone_telemetry
```

### Consultas Básicas

```bash
# Ver últimos registros
make query-drones

# O manualmente:
docker exec clickhouse clickhouse-client --query="
SELECT * FROM drone_telemetry.telemetry_data 
ORDER BY timestamp DESC 
LIMIT 10
"
```

### Consultas Avanzadas

```sql
-- 1. Drones activos en últimos 5 minutos
SELECT 
    drone_id,
    count() as messages,
    argMax(battery_level, timestamp) as battery,
    argMax(status, timestamp) as status
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 5 MINUTE
GROUP BY drone_id;

-- 2. Trayectoria de un dron
SELECT 
    timestamp,
    latitude,
    longitude,
    altitude
FROM drone_telemetry.telemetry_data
WHERE drone_id = 'DRONE_001'
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY timestamp DESC;

-- 3. Alertas de batería baja
SELECT 
    drone_id,
    battery_level,
    timestamp
FROM drone_telemetry.telemetry_data
WHERE battery_level < 20
  AND timestamp > now() - INTERVAL 1 HOUR
ORDER BY battery_level ASC;

-- 4. Estadísticas por dron
SELECT 
    drone_id,
    count() as total_messages,
    avg(battery_level) as avg_battery,
    avg(speed) as avg_speed,
    avg(altitude) as avg_altitude,
    min(timestamp) as first_seen,
    max(timestamp) as last_seen
FROM drone_telemetry.telemetry_data
GROUP BY drone_id;
```

### Exportar Datos

```bash
# Exportar a CSV
docker exec clickhouse clickhouse-client --query="
SELECT * FROM drone_telemetry.telemetry_data 
WHERE timestamp > now() - INTERVAL 1 DAY
" --format CSV > telemetry_export.csv

# Exportar a JSON
docker exec clickhouse clickhouse-client --query="
SELECT * FROM drone_telemetry.telemetry_data 
LIMIT 100
" --format JSONEachRow > telemetry_export.json

# Exportar resumen para análisis
docker exec clickhouse clickhouse-client --query="
SELECT 
    drone_id,
    toStartOfHour(timestamp) as hour,
    avg(battery_level) as avg_battery,
    avg(speed) as avg_speed,
    count() as messages
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 24 HOUR
GROUP BY drone_id, hour
ORDER BY drone_id, hour
" --format CSV > hourly_summary.csv
```

---

## Monitoreo con Grafana

### Acceder a Grafana

```bash
# Abrir en navegador
open http://localhost:3000  # macOS
xdg-open http://localhost:3000  # Linux

# Credenciales por defecto
Usuario: admin
Password: Grafana2025!
```

### Configurar Datasources

```bash
# Configurar automáticamente
/opt/drone-telemetry/config/monitoring/configure-grafana.sh

# O manualmente desde la UI:
# Configuration → Data Sources → Add data source
# - Prometheus: http://prometheus:9090
# - ClickHouse: http://clickhouse:8123
```

### Queries Útiles para Dashboards

**Panel 1: Drones Activos**
```sql
SELECT count(DISTINCT drone_id)
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 MINUTE
```

**Panel 2: Batería Promedio**
```sql
SELECT 
    toStartOfMinute(timestamp) as time,
    avg(battery_level) as avg_battery
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 1 HOUR
GROUP BY time
ORDER BY time
```

**Panel 3: Mapa de Posiciones**
```sql
SELECT 
    drone_id,
    argMax(latitude, timestamp) as lat,
    argMax(longitude, timestamp) as lon
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 5 MINUTE
GROUP BY drone_id
```

---

## Debugging y Troubleshooting

### Ver Logs

```bash
# Todos los contenedores
make logs

# Logs específicos
make logs-thingsboard
make logs-kafka
make logs-clickhouse
make logs-grafana

# O directamente
docker logs -f <container_name>
docker logs --tail 100 <container_name>
```

### Estado de Servicios

```bash
# Estado general
make status

# Contenedores en ejecución
docker ps

# Todos los contenedores (incluido detenidos)
docker ps -a

# Uso de recursos
docker stats
```

### Verificar Conectividad

```bash
# Puertos abiertos
netstat -tuln | grep -E '(1883|8080|9092|8123|3000)'

# Desde otro contenedor
docker exec thingsboard nc -zv kafka 9092
docker exec kafka nc -zv clickhouse 8123
```

### Kafka Debugging

```bash
# Listar topics
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Describir topic
docker exec kafka kafka-topics --describe \
    --topic drone-telemetry \
    --bootstrap-server localhost:9092

# Consumir mensajes (últimos 10)
docker exec kafka kafka-console-consumer \
    --bootstrap-server localhost:9092 \
    --topic drone-telemetry \
    --from-beginning \
    --max-messages 10

# Ver consumer groups
docker exec kafka kafka-consumer-groups --list \
    --bootstrap-server localhost:9092

# Ver lag de un consumer group
docker exec kafka kafka-consumer-groups --describe \
    --group clickhouse-sink \
    --bootstrap-server localhost:9092
```

### ThingsBoard Debugging

```bash
# Ver dispositivos creados
# Acceder a UI: http://localhost:8080
# Login: tenant@thingsboard.org / tenant
# Ir a: Entities → Devices

# Verificar telemetría de un dispositivo
# UI → Devices → [Seleccionar drone] → Latest Telemetry

# Ver reglas activas
# UI → Rule Chains
```

### ClickHouse Debugging

```bash
# Verificar tablas
docker exec clickhouse clickhouse-client --query="SHOW TABLES FROM drone_telemetry"

# Ver estructura de tabla
docker exec clickhouse clickhouse-client --query="DESCRIBE drone_telemetry.telemetry_data"

# Ver tamaño de tabla
docker exec clickhouse clickhouse-client --query="
SELECT 
    formatReadableSize(sum(bytes)) as size,
    sum(rows) as rows
FROM system.parts
WHERE database = 'drone_telemetry'
  AND table = 'telemetry_data'
  AND active
"

# Verificar particiones
docker exec clickhouse clickhouse-client --query="
SELECT partition, sum(rows) as rows
FROM system.parts
WHERE database = 'drone_telemetry'
  AND table = 'telemetry_data'
  AND active
GROUP BY partition
ORDER BY partition DESC
"
```

### Reiniciar Componentes

```bash
# Reiniciar todo
make restart

# Reiniciar componente específico
docker restart clickhouse
docker restart kafka
docker restart thingsboard
docker restart grafana

# Reiniciar con reconstrucción
docker-compose down
docker-compose up -d
```

### Backup y Restore

```bash
# Crear backup
make backup

# El backup se guarda en /tmp/drone-telemetry-backup-YYYYMMDD-HHMMSS

# Comprimir backup
tar -czf drone-backup.tar.gz /tmp/drone-telemetry-backup-*

# Restore (ejemplo)
sudo rm -rf /opt/drone-telemetry/data/clickhouse
sudo cp -r /tmp/drone-telemetry-backup-*/clickhouse /opt/drone-telemetry/data/
docker restart clickhouse
```

### Limpiar y Redesplegar

```bash
# Opción 1: Usando make (interactivo)
make clean

# Opción 2: Usando playbook
make undeploy

# Redesplegar desde cero
make deploy
```

---

## Casos de Uso Avanzados

### Integración con API de ThingsBoard

```python
import requests

TB_URL = "http://localhost:8080"
USERNAME = "tenant@thingsboard.org"
PASSWORD = "tenant"

# Obtener token
response = requests.post(
    f"{TB_URL}/api/auth/login",
    json={"username": USERNAME, "password": PASSWORD}
)
token = response.json()["token"]

# Listar dispositivos
headers = {"X-Authorization": f"Bearer {token}"}
devices = requests.get(f"{TB_URL}/api/tenant/devices?pageSize=100", headers=headers)
print(devices.json())
```

### Alertas Personalizadas

```sql
-- Query para identificar drones que necesitan atención
SELECT 
    drone_id,
    argMax(battery_level, timestamp) as battery,
    argMax(status, timestamp) as status,
    max(timestamp) as last_update,
    now() - max(timestamp) as time_offline
FROM drone_telemetry.telemetry_data
GROUP BY drone_id
HAVING battery < 15 OR time_offline > INTERVAL 10 MINUTE
```

### Análisis de Patrones

```sql
-- Detectar drones con comportamiento anómalo
WITH stats AS (
    SELECT 
        drone_id,
        avg(speed) as avg_speed,
        stddevPop(speed) as stddev_speed
    FROM drone_telemetry.telemetry_data
    WHERE timestamp > now() - INTERVAL 1 HOUR
    GROUP BY drone_id
)
SELECT 
    t.drone_id,
    t.timestamp,
    t.speed,
    s.avg_speed,
    abs(t.speed - s.avg_speed) as deviation
FROM drone_telemetry.telemetry_data t
JOIN stats s ON t.drone_id = s.drone_id
WHERE abs(t.speed - s.avg_speed) > 2 * s.stddev_speed
  AND t.timestamp > now() - INTERVAL 1 HOUR
ORDER BY deviation DESC
LIMIT 10
```

---

## Scripts Útiles

Todos los scripts están en `scripts/`:

- `verify-deployment.sh` - Verificar estado del sistema
- `start-all.sh` - Iniciar todos los servicios
- `stop-all.sh` - Detener todos los servicios
- `cleanup.sh` - Limpiar todo (DESTRUCTIVO)
- `backup.sh` - Crear backup de datos
- `setup-kafka-connect.py` - Configurar Kafka Connect

**Uso:**

```bash
# Dar permisos de ejecución (si es necesario)
chmod +x scripts/*.sh

# Ejecutar
./scripts/verify-deployment.sh
```

---

Para más información, consulta:
- [README.md](README.md) - Documentación principal
- [ARCHITECTURE.md](ARCHITECTURE.md) - Arquitectura detallada
- [QUICKSTART.md](QUICKSTART.md) - Guía rápida
