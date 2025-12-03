# Arquitectura Detallada del Sistema

## Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────┐
│                         CAPA DE DISPOSITIVOS                    │
│  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐  ┌────────┐   │
│  │Drone001│  │Drone002│  │Drone003│  │Drone004│  │Drone005│   │
│  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘  └───┬────┘   │
│      │           │           │           │           │         │
│      └───────────┴───────────┴───────────┴───────────┘         │
│                          │ MQTT 1883                            │
└──────────────────────────┼──────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CAPA DE INGESTA (IoT Platform)               │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │              ThingsBoard Community Edition              │   │
│  │  • Device Management    • Rule Engine                   │   │
│  │  • MQTT/HTTP/CoAP       • Data Validation               │   │
│  │  • Dashboard/Widgets    • Alarm Management              │   │
│  └────────────────────┬────────────────────────────────────┘   │
│                       │ Kafka Producer                          │
└───────────────────────┼─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CAPA DE MENSAJERÍA (Streaming)                 │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                    Apache Kafka                         │   │
│  │  ┌──────────────────────────────────────────────────┐   │   │
│  │  │  Topic: drone-telemetry                          │   │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐        │   │   │
│  │  │  │Partition0│ │Partition1│ │Partition2│        │   │   │
│  │  │  └──────────┘ └──────────┘ └──────────┘        │   │   │
│  │  └──────────────────────────────────────────────────┘   │   │
│  │                                                          │   │
│  │  Zookeeper (Coordination)                               │   │
│  └────────────────────┬─────────────────────────────────────┘  │
│                       │ Kafka Consumer                          │
└───────────────────────┼─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│                 CAPA DE ALMACENAMIENTO (OLAP)                   │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │                      ClickHouse                         │   │
│  │  Database: drone_telemetry                              │   │
│  │  ┌──────────────────────────────────────────────────┐   │   │
│  │  │ Table: telemetry_data                            │   │   │
│  │  │ Engine: MergeTree()                               │   │   │
│  │  │ Partition: toYYYYMM(timestamp)                   │   │   │
│  │  │ Order: (drone_id, timestamp)                     │   │   │
│  │  │                                                   │   │   │
│  │  │ Columns:                                          │   │   │
│  │  │  - timestamp (DateTime64)                        │   │   │
│  │  │  - drone_id (String)                             │   │   │
│  │  │  - latitude, longitude (Float64)                 │   │   │
│  │  │  - altitude (Float64)                             │   │   │
│  │  │  - battery_level (Float32)                       │   │   │
│  │  │  - speed, temperature (Float32)                  │   │   │
│  │  │  - status, mission_id (String)                   │   │   │
│  │  └──────────────────────────────────────────────────┘   │   │
│  └─────────────────────────────────────────────────────────┘   │
└───────────────────────┬─────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────────────────┐
│              CAPA DE VISUALIZACIÓN Y MONITOREO                  │
│  ┌─────────────────────┐      ┌──────────────────────────┐     │
│  │     Grafana         │      │      Prometheus          │     │
│  │  • Dashboards       │◄─────┤  • Metrics Collection    │     │
│  │  • Alerts           │      │  • Time Series DB        │     │
│  │  • ClickHouse DS    │      │  • Alert Manager         │     │
│  └─────────────────────┘      └──────────────────────────┘     │
└─────────────────────────────────────────────────────────────────┘
```

## Flujo de Datos Detallado

### 1. Generación de Telemetría

**Drones** (Simulados):
- Frecuencia: 15 segundos
- Protocolo: MQTT
- Formato: JSON

**Payload ejemplo:**
```json
{
  "timestamp": "2025-12-03T14:30:15.000Z",
  "latitude": 40.4168,
  "longitude": -3.7038,
  "altitude": 120.5,
  "battery_level": 85.3,
  "speed": 25.8,
  "temperature": 22.4,
  "status": "ACTIVE",
  "mission_id": "MISSION_1234"
}
```

### 2. Ingesta en ThingsBoard

**Proceso:**
1. Drone publica a `v1/devices/me/telemetry`
2. ThingsBoard valida access token
3. Ejecuta rule chain (opcional):
   - Validación de datos
   - Enriquecimiento
   - Generación de alarmas
4. Publica a Kafka topic

### 3. Enrutamiento vía Kafka

**Características:**
- Topic: `drone-telemetry`
- Partitioning: Por `drone_id` (hash)
- Retention: 7 días
- Compression: LZ4

**Ventajas:**
- Buffer ante caídas
- Múltiples consumidores
- Replay de mensajes

### 4. Almacenamiento en ClickHouse

**Kafka Connect Sink:**
- Consume de topic
- Batch inserts (1000 registros o 10s)
- Error handling con dead letter queue

**Optimizaciones:**
- Partición mensual automática
- Compresión Delta + LZ4
- TTL: 1 año (configurable)

### 5. Consultas y Visualización

**Grafana:**
- Datasource: ClickHouse plugin
- Refresh: 5 segundos
- Consultas optimizadas con índices

**Queries típicas:**
```sql
-- Última posición de cada dron
SELECT 
    drone_id,
    argMax(latitude, timestamp) as last_lat,
    argMax(longitude, timestamp) as last_lon,
    argMax(battery_level, timestamp) as battery
FROM drone_telemetry.telemetry_data
WHERE timestamp > now() - INTERVAL 5 MINUTE
GROUP BY drone_id
```

## Especificaciones de Red

### Puertos Externos (Host)
```
8080   → ThingsBoard HTTP UI
1883   → ThingsBoard MQTT
5683   → ThingsBoard CoAP
9092   → Kafka Broker
2181   → Zookeeper
8123   → ClickHouse HTTP
9000   → ClickHouse Native
3000   → Grafana
9090   → Prometheus
9100   → Node Exporter
```

### Red Docker (drone_network)
```
Subnet: 172.25.0.0/16
Gateway: 172.25.0.1

Contenedores:
- clickhouse
- kafka
- zookeeper
- thingsboard
- postgres-tb
- grafana
- prometheus
- node-exporter
- kafka-connect
```

## Persistencia

### Volúmenes

```
/opt/drone-telemetry/
├── data/
│   ├── clickhouse/        # ~10GB (estimado para 1M registros)
│   ├── kafka/             # ~5GB (7 días retention)
│   ├── zookeeper/         # ~100MB
│   ├── thingsboard/       # ~2GB
│   │   ├── data/
│   │   └── postgres/
│   ├── grafana/           # ~500MB
│   └── prometheus/        # ~2GB (15 días retention)
├── logs/
│   ├── thingsboard/
│   └── drone-simulator/
└── config/
    ├── clickhouse/
    ├── monitoring/
    └── kafka-connect-docker-compose.yml
```

## Seguridad

### Autenticación
- ThingsBoard: Usuario/contraseña + Access tokens
- ClickHouse: Usuario/contraseña
- Grafana: Usuario/contraseña
- Kafka: Ninguna (red interna)

### Red
- Docker network aislada
- Solo puertos necesarios expuestos
- Comunicación interna por nombres DNS

### Datos
- Sin encriptación en tránsito (producción requiere TLS)
- Backups manuales (scripts provistos)

## Escalabilidad

### Vertical
- **ClickHouse**: Hasta 256 cores
- **Kafka**: Hasta 64GB RAM por broker
- **ThingsBoard**: Hasta 32GB RAM

### Horizontal
- **Kafka**: Hasta 100 brokers
- **ClickHouse**: Cluster con replicación
- **ThingsBoard**: Modo cluster con Redis

### Límites Actuales (Single Node)
- Drones: ~1000 simultáneos
- Mensajes/seg: ~10,000
- Almacenamiento: ~100M registros
- Consultas/seg: ~100

## Monitoreo

### Métricas Clave

**Sistema:**
- CPU, RAM, Disco, Red (Node Exporter)

**Kafka:**
- Messages in/out per second
- Consumer lag
- Partition count

**ClickHouse:**
- Query duration
- Insert rate
- Table size

**ThingsBoard:**
- Active devices
- Messages processed
- Rule engine latency

### Alertas Recomendadas

```yaml
# Ejemplos de alertas críticas
- Battery < 10%
- Device offline > 5min
- Kafka consumer lag > 1000
- Disk usage > 80%
- CPU > 90% for 5min
```

## Referencias

- [ThingsBoard Docs](https://thingsboard.io/docs/)
- [Kafka Docs](https://kafka.apache.org/documentation/)
- [ClickHouse Docs](https://clickhouse.com/docs/)
- [Grafana Docs](https://grafana.com/docs/)
