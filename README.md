# Sistema de Telemetría para Drones de Vigilancia

[![Ansible](https://img.shields.io/badge/Ansible-2.15+-red.svg)](https://www.ansible.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04%20LTS-orange.svg)](https://ubuntu.com/)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Sistema automatizado de despliegue on-premise para recepción, procesamiento y visualización de telemetría de drones de vigilancia usando Ansible.

## 📋 Tabla de Contenidos

- [Descripción](#-descripción)
- [Arquitectura del Sistema](#-arquitectura-del-sistema)
- [Componentes](#-componentes)
- [Requisitos Previos](#-requisitos-previos)
- [Instalación y Despliegue](#-instalación-y-despliegue)
- [Configuración](#-configuración)
- [Uso](#-uso)
- [Monitoreo](#-monitoreo)
- [Decisiones Técnicas](#-decisiones-técnicas)
- [Troubleshooting](#-troubleshooting)
- [Contribución](#-contribución)

## 🎯 Descripción

Este proyecto automatiza el despliegue de una infraestructura completa para:

- Recibir telemetría de drones cada 15 segundos vía MQTT
- Enrutar mensajes a través de Apache Kafka
- Almacenar datos en ClickHouse (base de datos de series temporales)
- Visualizar información en tiempo real con ThingsBoard
- Monitorear el sistema con Prometheus y Grafana

## 🏗 Arquitectura del Sistema

```
┌─────────────────┐
│  Drones (5x)    │
│  MQTT Client    │
└────────┬────────┘
         │ MQTT (Port 1883)
         │ Telemetría cada 15s
         ▼
┌─────────────────────────────┐
│     ThingsBoard CE          │
│  - Recepción MQTT/HTTP      │
│  - Visualización IoT        │
│  - Reglas de procesamiento  │
└────────┬────────────────────┘
         │ Kafka Producer
         ▼
┌─────────────────────────────┐
│     Apache Kafka            │
│  - Topic: drone-telemetry   │
│  - 3 Partitions             │
│  - Zookeeper                │
└────────┬────────────────────┘
         │ Kafka Consumer
         ▼
┌─────────────────────────────┐
│     ClickHouse              │
│  - Time-Series Database     │
│  - Tabla: telemetry_data    │
│  - Partición por mes        │
└─────────────────────────────┘
         │
         ▼
┌─────────────────────────────┐
│  Grafana + Prometheus       │
│  - Dashboards               │
│  - Métricas del sistema     │
│  - Alertas                  │
└─────────────────────────────┘
```

### Flujo de Datos

1. **Drones** → Envían telemetría vía MQTT a ThingsBoard
2. **ThingsBoard** → Procesa y publica en Kafka topic
3. **Kafka** → Distribuye mensajes a consumidores
4. **ClickHouse** → Almacena datos para análisis histórico
5. **Grafana** → Visualiza métricas y telemetría

## 🔧 Componentes

### ThingsBoard Community Edition (v3.6.2)
- **Puerto HTTP**: 8080
- **Puerto MQTT**: 1883
- **Puerto CoAP**: 5683
- Plataforma IoT para gestión de dispositivos y visualización

### Apache Kafka (v3.6.1)
- **Puerto Broker**: 9092
- **Puerto Zookeeper**: 2181
- **Topic**: `drone-telemetry` (3 particiones)
- Sistema de mensajería distribuida

### ClickHouse (v23.12)
- **Puerto HTTP**: 8123
- **Puerto Nativo**: 9000
- **Base de datos**: `drone_telemetry`
- **Tabla**: `telemetry_data`
- Almacenamiento columnar optimizado para series temporales

### Grafana (v10.2.3) + Prometheus (v2.48.1)
- **Puerto Grafana**: 3000
- **Puerto Prometheus**: 9090
- Stack de monitoreo y visualización

### Simulador de Drones
- Simula 5 drones enviando telemetría cada 15 segundos
- Datos: GPS, batería, velocidad, temperatura, estado
- Implementado en Python con paho-mqtt

## 📦 Requisitos Previos

### Sistema Operativo
- **Ubuntu Server 22.04 LTS** (recomendado)
- Otras distribuciones Debian-based pueden funcionar con ajustes

### Hardware Mínimo
- **CPU**: 4 cores
- **RAM**: 8 GB
- **Disco**: 50 GB libres
- **Red**: Conexión a Internet para descargar imágenes Docker

### Software
- **Ansible**: >= 2.15
- **Python**: >= 3.8
- **SSH**: Acceso configurado (si es remoto)

### Permisos
- Usuario con privilegios `sudo`
- Sin contraseña sudo configurada (o usar `--ask-become-pass`)

## 🚀 Instalación y Despliegue

### 1. Clonar el Repositorio

```bash
git clone https://github.com/luhercentti/ansible-automation-demo-drones.git
cd ansible-automation-demo-drones
```

### 2. Instalar Ansible (si no está instalado)

```bash
# En Ubuntu/Debian
sudo apt update
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible

# Verificar instalación
ansible --version
```

### 3. Configurar el Inventario

Editar `inventory/hosts.yml` para ajustar el host objetivo:

```yaml
# Para despliegue local
drone-server-01:
  ansible_host: localhost
  ansible_connection: local

# Para despliegue remoto
drone-server-01:
  ansible_host: 192.168.1.100
  ansible_user: ubuntu
  ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### 4. Personalizar Variables (Opcional)

Editar `group_vars/all.yml` para personalizar:

```yaml
# Número de drones a simular
drone_simulator_count: 5

# Intervalo de telemetría (segundos)
drone_telemetry_interval: 15

# Habilitar monitoreo
use_monitoring: true
```

### 5. Ejecutar el Playbook

**Despliegue completo:**

```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

**Despliegue por componentes (usando tags):**

```bash
# Solo prerequisitos
ansible-playbook -i inventory/hosts.yml site.yml --tags "common"

# Solo base de datos
ansible-playbook -i inventory/hosts.yml site.yml --tags "clickhouse"

# Solo Kafka
ansible-playbook -i inventory/hosts.yml site.yml --tags "kafka"

# Solo ThingsBoard
ansible-playbook -i inventory/hosts.yml site.yml --tags "thingsboard"

# Solo monitoreo
ansible-playbook -i inventory/hosts.yml site.yml --tags "monitoring"

# Solo simulador
ansible-playbook -i inventory/hosts.yml site.yml --tags "simulator"
```

**Con contraseña sudo:**

```bash
ansible-playbook -i inventory/hosts.yml site.yml --ask-become-pass
```

### 6. Tiempo de Despliegue

El despliegue completo toma aproximadamente **15-20 minutos** dependiendo de:
- Velocidad de conexión a Internet
- Recursos del servidor
- Si las imágenes Docker ya están en caché

## ⚙️ Configuración

### Acceso a los Componentes

Una vez desplegado, los servicios están disponibles en:

| Servicio | URL | Credenciales |
|----------|-----|--------------|
| **ThingsBoard** | http://localhost:8080 | System: `sysadmin@thingsboard.org` / `sysadmin`<br>Tenant: `tenant@thingsboard.org` / `tenant` |
| **ClickHouse** | http://localhost:8123 | User: `droneuser`<br>Password: `ClickHouse2025!` |
| **Kafka** | localhost:9092 | Sin autenticación |
| **Grafana** | http://localhost:3000 | User: `admin`<br>Password: `Grafana2025!` |
| **Prometheus** | http://localhost:9090 | Sin autenticación |

### Provisionar Dispositivos en ThingsBoard

Antes de iniciar el simulador, crear los dispositivos (drones) en ThingsBoard:

```bash
python3 /opt/drone-telemetry/drone-simulator/provision_devices.py
```

Este script:
1. Se conecta a ThingsBoard con credenciales de tenant
2. Crea 5 dispositivos tipo "Surveillance Drone"
3. Genera tokens de acceso para cada dron

### Iniciar Simulador de Drones

```bash
# Iniciar manualmente
/opt/drone-telemetry/drone-simulator/start_drones.sh

# O como servicio systemd
sudo systemctl enable drone-simulator
sudo systemctl start drone-simulator

# Ver logs
sudo journalctl -u drone-simulator -f
```

### Verificar Datos en ClickHouse

```bash
# Conectar a ClickHouse
docker exec -it clickhouse clickhouse-client

# Consultar datos
SELECT 
    drone_id, 
    toDateTime(timestamp) as time,
    battery_level,
    status
FROM drone_telemetry.telemetry_data
ORDER BY timestamp DESC
LIMIT 10;

# Contar registros por drone
SELECT 
    drone_id,
    count() as messages
FROM drone_telemetry.telemetry_data
GROUP BY drone_id;
```

## 📊 Monitoreo

### Grafana Dashboards

1. Acceder a Grafana: http://localhost:3000
2. Login con credenciales configuradas
3. Configurar datasources:

```bash
/opt/drone-telemetry/config/monitoring/configure-grafana.sh
```

4. Importar dashboards:
   - **Drone Telemetry**: Visualización de posiciones, batería, altitud
   - **System Metrics**: CPU, memoria, disco, red
   - **Kafka Metrics**: Throughput, lag, partitions

### Prometheus Métricas

Acceder a Prometheus: http://localhost:9090

Consultas útiles:

```promql
# Tasa de mensajes Kafka
rate(kafka_server_brokertopicmetrics_messagesin_total[5m])

# Uso de CPU
100 - (avg by (instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Uso de memoria
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
```

### Alertas (Configuración Opcional)

Editar `roles/monitoring/files/alert-rules.yml` para definir alertas personalizadas:

```yaml
groups:
  - name: drone_alerts
    rules:
      - alert: DroneBatteryLow
        expr: battery_level < 20
        for: 1m
        annotations:
          summary: "Drone {{ $labels.drone_id }} battery critical"
```

## 💡 Decisiones Técnicas

### ¿Por qué Docker?

**Ventajas:**
- **Portabilidad**: Mismo entorno en desarrollo y producción
- **Aislamiento**: Cada servicio en su propio contenedor
- **Facilidad de gestión**: Fácil inicio, parada, y actualización
- **Consistencia**: Versiones específicas garantizadas

**Alternativa considerada**: Instalación nativa con systemd
- Rechazada por complejidad de gestión de dependencias
- Dificulta actualizaciones y rollbacks

### ¿Por qué ClickHouse en lugar de TimescaleDB o InfluxDB?

**ClickHouse seleccionado por:**
- **Rendimiento**: Consultas analíticas 100-1000x más rápidas
- **Compresión**: Reduce almacenamiento hasta 90%
- **Escalabilidad**: Maneja billones de registros
- **SQL estándar**: Fácil para analistas

**TimescaleDB**: Considerado pero descartado
- Basado en PostgreSQL, menor rendimiento en agregaciones
- Mayor consumo de recursos

**InfluxDB**: Considerado pero descartado
- Licencia empresarial restrictiva
- Lenguaje de consulta propietario (InfluxQL/Flux)

### ¿Por qué Kafka y no RabbitMQ o MQTT directo?

**Kafka elegido por:**
- **Persistencia**: Mensajes almacenados en disco, replay posible
- **Escalabilidad horizontal**: Particiones distribuidas
- **Throughput alto**: Millones de mensajes/segundo
- **Ecosistema**: Kafka Connect para integraciones

**RabbitMQ**: Descartado
- Diseñado para enrutamiento complejo, no persistencia masiva
- Menor throughput

**MQTT directo a ClickHouse**: Descartado
- Sin buffer ante caídas de ClickHouse
- Sin capacidad de múltiples consumidores

### Estructura de Roles Ansible

```
roles/
├── common/          # Prerequisitos (Docker, Python)
├── clickhouse/      # Base de datos
├── kafka/           # Mensajería
├── thingsboard/     # Plataforma IoT
├── monitoring/      # Grafana + Prometheus
└── drone_simulator/ # Simulación de drones
```

**Ventajas:**
- **Modularidad**: Cada rol independiente y reutilizable
- **Testabilidad**: Probar componentes individualmente
- **Mantenibilidad**: Cambios aislados sin afectar otros componentes

### Configuración de Red Docker

Red bridge personalizada (`drone_network`):
- Permite comunicación entre contenedores por nombre
- Aislamiento de red del host
- Subnet: `172.25.0.0/16`

### Persistencia de Datos

Volúmenes Docker montados en:
```
/opt/drone-telemetry/data/
├── clickhouse/
├── kafka/
├── zookeeper/
├── thingsboard/
└── grafana/
```

**Ventajas:**
- Datos persisten tras reinicio de contenedores
- Fácil backup (`tar` del directorio)
- Fácil migración a otro servidor

## 🐛 Troubleshooting

### Problema: Ansible falla en "Install Docker"

**Causa**: Repositorio Docker no accesible o GPG key inválida

**Solución:**
```bash
# Limpiar keys antiguas
sudo rm /usr/share/keyrings/docker-archive-keyring.gpg

# Re-ejecutar playbook
ansible-playbook -i inventory/hosts.yml site.yml --tags "common"
```

### Problema: ThingsBoard no inicia

**Causa**: PostgreSQL no está listo

**Solución:**
```bash
# Verificar PostgreSQL
docker logs postgres-tb

# Reiniciar ThingsBoard
docker restart thingsboard

# Ver logs
docker logs -f thingsboard
```

### Problema: Kafka no recibe mensajes

**Causa**: Zookeeper no conectado

**Solución:**
```bash
# Verificar Zookeeper
docker exec zookeeper zookeeper-shell.sh localhost:2181 ls /brokers/ids

# Verificar topic
docker exec kafka kafka-topics --list --bootstrap-server localhost:9092

# Ver logs
docker logs kafka
```

### Problema: ClickHouse rechaza conexiones

**Causa**: Usuario/password incorrectos

**Solución:**
```bash
# Verificar configuración de usuarios
docker exec clickhouse cat /etc/clickhouse-server/users.d/custom-users.xml

# Probar conexión
docker exec clickhouse clickhouse-client --user droneuser --password ClickHouse2025!
```

### Problema: Drones no envían datos

**Causa**: Dispositivos no provisionados en ThingsBoard

**Solución:**
```bash
# Provisionar dispositivos
python3 /opt/drone-telemetry/drone-simulator/provision_devices.py

# Verificar en ThingsBoard UI
# Devices → Crear manualmente si script falla
```

### Logs Centralizados

```bash
# Ver todos los contenedores
docker ps -a

# Logs de un servicio específico
docker logs -f <container_name>

# Logs del simulador
tail -f /opt/drone-telemetry/logs/drone-simulator.log
```

## 📈 Escalabilidad

### Para Producción

**Escalar horizontalmente:**

1. **Kafka**: Agregar más brokers
   ```yaml
   # En group_vars/all.yml
   kafka_replication_factor: 3
   kafka_partitions: 6
   ```

2. **ClickHouse**: Cluster con replicación
   ```yaml
   # Usar ClickHouse Keeper en lugar de single node
   ```

3. **ThingsBoard**: Modo cluster
   ```yaml
   # Múltiples instancias con load balancer
   ```

### Optimizaciones

**ClickHouse:**
```sql
-- Optimizar tabla con codec de compresión
ALTER TABLE drone_telemetry.telemetry_data 
MODIFY COLUMN battery_level Float32 CODEC(Delta, LZ4);
```

**Kafka:**
```yaml
# Aumentar retention
KAFKA_LOG_RETENTION_HOURS: 168  # 7 días
```

## 🧪 Testing

### Verificar Despliegue

```bash
# Ejecutar script de verificación
./scripts/verify-deployment.sh
```

### Tests de Integración

```bash
# Enviar mensaje de prueba a ThingsBoard
curl -X POST http://localhost:8080/api/v1/DEVICE_TOKEN/telemetry \
  -H "Content-Type: application/json" \
  -d '{"temperature":25, "humidity":60}'

# Verificar en Kafka
docker exec kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic drone-telemetry \
  --from-beginning \
  --max-messages 1
```

## 📝 Próximos Pasos / Mejoras Futuras

- [ ] Implementar autenticación Kafka con SASL/SSL
- [ ] Agregar Kafka Connect Sink para ClickHouse automático
- [ ] Dashboard avanzado de Grafana con mapas en tiempo real
- [ ] Alertas por Telegram/Slack
- [ ] CI/CD con GitHub Actions
- [ ] Tests automatizados con Molecule
- [ ] Soporte para Kubernetes (Helm charts)
- [ ] Encryption en tránsito (TLS)
- [ ] Backup automatizado con restic/duplicity

## 📄 Licencia

Este proyecto está bajo la licencia MIT. Ver archivo [LICENSE](LICENSE) para más detalles.

## 👥 Contribución

Contribuciones son bienvenidas! Por favor:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📧 Contacto

**Autor**: Luis Angelo Hernández  
**Email**: luis@example.com  
**GitHub**: [@luhercentti](https://github.com/luhercentti)

---

**⭐ Si este proyecto te fue útil, considera darle una estrella en GitHub!**
