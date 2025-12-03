# Changelog

Todos los cambios notables en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/lang/es/).

## [1.0.0] - 2025-12-03

### Añadido

#### Infraestructura Core
- Sistema completo de despliegue automatizado con Ansible
- Soporte para Ubuntu 22.04 LTS
- Despliegue basado en Docker para todos los componentes
- Red Docker aislada (`drone_network`) para comunicación entre servicios

#### Componentes Principales
- **ThingsBoard CE 3.6.2**: Plataforma IoT para gestión de dispositivos
  - Soporte MQTT (puerto 1883)
  - Soporte HTTP/CoAP
  - Integración con Kafka
  - PostgreSQL 15 como base de datos

- **Apache Kafka 3.6.1**: Sistema de mensajería distribuida
  - Zookeeper para coordinación
  - Topic `drone-telemetry` con 3 particiones
  - Kafka Connect para integraciones
  - JMX metrics en puerto 9999

- **ClickHouse 23.12**: Base de datos columnar
  - Tabla `telemetry_data` con MergeTree engine
  - Particionamiento mensual automático
  - Optimizaciones de compresión
  - Soporte HTTP (8123) y Native (9000)

- **Grafana 10.2.3**: Visualización y dashboards
  - Datasource para Prometheus
  - Datasource para ClickHouse
  - Configuración automática

- **Prometheus 2.48.1**: Métricas del sistema
  - Node Exporter para métricas de host
  - Scraping de Kafka, ClickHouse
  - Retention de 15 días

#### Simulador de Drones
- Simulador Python con paho-mqtt
- Soporte para múltiples drones (configurable)
- Telemetría cada 15 segundos (configurable)
- Datos simulados:
  - GPS (latitud, longitud, altitud)
  - Batería con descarga gradual
  - Velocidad variable
  - Temperatura
  - Estado del dron
  - Mission ID

- Servicio systemd para ejecución continua
- Script de provisionamiento de dispositivos en ThingsBoard

#### Roles Ansible
- `common`: Instalación de Docker, Docker Compose, Python
- `clickhouse`: Despliegue y configuración de ClickHouse
- `kafka`: Despliegue de Kafka y Zookeeper
- `thingsboard`: Despliegue de ThingsBoard con PostgreSQL
- `monitoring`: Despliegue de Grafana, Prometheus, Node Exporter
- `drone_simulator`: Instalación del simulador de drones

#### Documentación
- README.md completo con:
  - Arquitectura del sistema
  - Guía de instalación paso a paso
  - Decisiones técnicas justificadas
  - Troubleshooting
  - Ejemplos de uso

- ARCHITECTURE.md: Documentación técnica detallada
- QUICKSTART.md: Guía de inicio rápido
- EXAMPLES.md: Casos de uso prácticos
- CONTRIBUTING.md: Guía para contribuidores
- REQUIREMENTS.txt: Requisitos del sistema

#### Scripts Utilitarios
- `verify-deployment.sh`: Verificación del estado del sistema
- `start-all.sh`: Inicio de todos los servicios
- `stop-all.sh`: Detención de servicios
- `cleanup.sh`: Limpieza completa del sistema
- `backup.sh`: Backup de datos
- `setup-kafka-connect.py`: Configuración de Kafka Connect

#### Makefile
- Comandos simplificados para todas las operaciones
- `make deploy`: Despliegue completo
- `make verify`: Verificación del sistema
- `make status`: Estado de servicios
- `make logs-*`: Ver logs de componentes específicos
- Y muchos más comandos útiles

#### Consultas SQL
- Colección completa de queries útiles en `docs/clickhouse-queries.sql`
- Análisis de batería, posición, velocidad
- Detección de anomalías
- Queries de mantenimiento

#### Playbooks Adicionales
- `update.yml`: Actualización de componentes
- `undeploy.yml`: Eliminación completa del sistema

#### Configuración
- Variables centralizadas en `group_vars/all.yml`
- Inventario flexible en `inventory/hosts.yml`
- Soporte para despliegue local y remoto
- Tags para despliegue selectivo

### Características Técnicas

#### Seguridad
- Usuarios y contraseñas configurables
- Red Docker aislada
- Solo puertos necesarios expuestos

#### Persistencia
- Volúmenes Docker en `/opt/drone-telemetry/data/`
- Datos persisten entre reinicios
- Scripts de backup incluidos

#### Escalabilidad
- Arquitectura preparada para escalar horizontalmente
- Kafka con múltiples particiones
- ClickHouse optimizado para grandes volúmenes

#### Monitoreo
- Métricas de sistema con Prometheus
- Node Exporter para métricas de host
- Dashboards Grafana configurables

### Flujo de Datos Completo
1. Drones → MQTT → ThingsBoard
2. ThingsBoard → Kafka Producer
3. Kafka Topic → Kafka Connect
4. Kafka Connect → ClickHouse
5. ClickHouse ← Grafana (visualización)

### Testing
- Verificación automática de servicios
- Scripts de validación incluidos
- Simulador para pruebas end-to-end

## [Unreleased]

### Planeado para Próxima Versión

- Autenticación Kafka con SASL/SSL
- Kafka Connect Sink automático para ClickHouse
- Dashboards Grafana pre-configurados importados automáticamente
- Tests automatizados con Molecule
- CI/CD con GitHub Actions
- Soporte para clusters multi-nodo
- Alertas vía Telegram/Slack
- Backup automatizado con cron

---

## Notas de Versión

### Versión 1.0.0 - Release Inicial

Esta es la primera versión completa del sistema de telemetría de drones. Incluye:

- ✅ Despliegue completamente automatizado
- ✅ Todos los componentes funcionando en conjunto
- ✅ Simulador de drones funcional
- ✅ Documentación completa
- ✅ Scripts de utilidad
- ✅ Buenas prácticas DevOps

**Probado en:**
- Ubuntu 22.04 LTS
- 8 GB RAM
- 4 CPU cores
- 50 GB disco

**Tiempo de despliegue:** ~15-20 minutos (primera vez)

**Componentes desplegados:**
- 9 contenedores Docker
- 1 servicio systemd (simulador)
- Base de datos persistente
- Stack de monitoreo completo

---

Para más detalles sobre cada componente, ver [README.md](README.md) y [ARCHITECTURE.md](ARCHITECTURE.md).
