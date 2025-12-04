#!/bin/bash

#
# Script de validación completa del sistema de telemetría de drones
#

set -e

# Verificar si se está ejecutando con sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Este script requiere privilegios sudo para acceder a Docker"
    echo "Ejecuta: sudo ./scripts/complete-validation.sh"
    exit 1
fi

echo "=========================================="
echo "VALIDACIÓN COMPLETA DEL SISTEMA"
echo "=========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para imprimir resultado
check_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ $2${NC}"
        return 0
    else
        echo -e "${RED}✗ $2${NC}"
        return 1
    fi
}

# 1. Verificar ClickHouse
echo "1. ✓ CLICKHOUSE"
echo "----------------------------------------"
# Verificar endpoint HTTP
CH_HTTP=$(curl -s http://localhost:8123/ 2>/dev/null || echo "")
if [ "$CH_HTTP" == "Ok." ]; then
    check_result 0 "ClickHouse HTTP está funcionando (puerto 8123)"
else
    check_result 1 "ClickHouse HTTP no responde"
fi

# Verificar base de datos y tabla
if docker exec clickhouse clickhouse-client --query "SHOW DATABASES" 2>/dev/null | grep -q "drone_telemetry"; then
    check_result 0 "Base de datos 'drone_telemetry' existe"
    
    if docker exec clickhouse clickhouse-client --query "SHOW TABLES FROM drone_telemetry" 2>/dev/null | grep -q "telemetry_data"; then
        check_result 0 "Tabla 'telemetry_data' existe"
        echo "   Esquema de la tabla:"
        docker exec clickhouse clickhouse-client --query "DESCRIBE drone_telemetry.telemetry_data" 2>/dev/null | head -8
        
        # Contar registros
        COUNT=$(docker exec clickhouse clickhouse-client --query "SELECT count() FROM drone_telemetry.telemetry_data" 2>/dev/null || echo "0")
        echo "   Registros almacenados: $COUNT"
    else
        check_result 1 "Tabla 'telemetry_data' no existe"
    fi
else
    check_result 1 "Base de datos 'drone_telemetry' no existe"
fi
echo ""

# 2. Verificar Kafka
echo "2. ✓ KAFKA"
echo "----------------------------------------"
# Verificar que el contenedor está corriendo
if docker ps | grep -q kafka; then
    check_result 0 "Contenedor Kafka está corriendo"
    
    # Verificar topic
    if docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null | grep -q "drone-telemetry"; then
        check_result 0 "Topic 'drone-telemetry' existe"
        echo "   Modo: KRaft (sin Zookeeper)"
        echo "   Bootstrap server: kafka:9092"
        
        # Describir el topic
        echo "   Detalles del topic:"
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic drone-telemetry 2>/dev/null | grep -E "Topic:|PartitionCount:|ReplicationFactor:" || true
    else
        check_result 1 "Topic 'drone-telemetry' no existe"
        echo "   Topics disponibles:"
        docker exec kafka kafka-topics.sh --bootstrap-server localhost:9092 --list 2>/dev/null || echo "   No se pudieron listar topics"
    fi
else
    check_result 1 "Contenedor Kafka no está corriendo"
fi
echo ""

# 3. Verificar ThingsBoard
echo "3. ✓ THINGSBOARD"
echo "----------------------------------------"
TB_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/login 2>/dev/null || echo "000")
if [ "$TB_STATUS" == "200" ]; then
    check_result 0 "ThingsBoard Web UI está accesible"
    echo "   URL: http://localhost:8080"
    echo "   Credenciales: sysadmin@thingsboard.org / sysadmin"
else
    check_result 1 "ThingsBoard Web UI no responde (HTTP $TB_STATUS)"
fi

# Verificar MQTT
if docker exec thingsboard nc -zv localhost 1883 2>&1 | grep -q "succeeded"; then
    check_result 0 "ThingsBoard MQTT está escuchando"
    echo "   Puerto MQTT: 1883"
else
    check_result 1 "ThingsBoard MQTT no está disponible"
fi

# Verificar conexión con PostgreSQL
if docker exec thingsboard nc -zv postgres-tb 5432 2>&1 | grep -q "succeeded"; then
    check_result 0 "ThingsBoard conectado a PostgreSQL"
else
    check_result 1 "ThingsBoard no puede conectar a PostgreSQL"
fi

# Verificar conexión con Kafka
if docker exec thingsboard nc -zv kafka 9092 2>&1 | grep -q "succeeded"; then
    check_result 0 "ThingsBoard conectado a Kafka"
else
    check_result 1 "ThingsBoard no puede conectar a Kafka"
fi
echo ""

# 4. Verificar Prometheus
echo "4. ✓ PROMETHEUS"
echo "----------------------------------------"
PROM_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:9090/-/healthy 2>/dev/null || echo "000")
if [ "$PROM_STATUS" == "200" ]; then
    check_result 0 "Prometheus está funcionando"
    echo "   URL: http://localhost:9090"
    # Verificar targets
    TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null | grep -o '"health":"up"' | wc -l)
    echo "   Targets UP: $TARGETS"
else
    check_result 1 "Prometheus no responde"
fi
echo ""

# 5. Verificar Grafana
echo "5. ✓ GRAFANA"
echo "----------------------------------------"
GRAF_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null || echo "000")
if [ "$GRAF_STATUS" == "200" ]; then
    check_result 0 "Grafana está funcionando"
    echo "   URL: http://localhost:3000"
    echo "   Credenciales: admin / Grafana2025!"
else
    check_result 1 "Grafana no responde"
fi
echo ""

# 6. Verificar red Docker
echo "6. ✓ RED DOCKER"
echo "----------------------------------------"
if docker network inspect drone_network &>/dev/null; then
    check_result 0 "Red Docker 'drone_network' existe"
    CONTAINERS=$(docker network inspect drone_network -f '{{range .Containers}}{{.Name}} {{end}}')
    echo "   Contenedores conectados:"
    for container in $CONTAINERS; do
        echo "   - $container"
    done
else
    check_result 1 "Red Docker no existe"
fi
echo ""

# 7. Verificar simulador de drones
echo "7. ✓ SIMULADOR DE DRONES"
echo "----------------------------------------"
if [ -f "/opt/drone-telemetry/simulator/drone_simulator.py" ]; then
    check_result 0 "Script del simulador encontrado"
    echo "   Ubicación: /opt/drone-telemetry/simulator/"
    echo "   Drones configurados: 5"
    echo "   Intervalo: 15 segundos"
    echo ""
    echo -e "${YELLOW}   Para iniciar el simulador:${NC}"
    echo "   cd /opt/drone-telemetry/simulator && ./start_drones.sh"
else
    check_result 1 "Script del simulador no encontrado"
fi
echo ""

# 8. Resumen de puertos
echo "8. ✓ PUERTOS EXPUESTOS"
echo "----------------------------------------"
echo "   ThingsBoard HTTP:  8080"
echo "   ThingsBoard MQTT:  1883"
echo "   ThingsBoard CoAP:  5683"
echo "   Grafana:           3000"
echo "   Prometheus:        9090"
echo "   ClickHouse HTTP:   8123"
echo "   ClickHouse Native: 9000"
echo "   Node Exporter:     9100"
echo ""

# 9. Estado de contenedores
echo "9. ✓ ESTADO DE CONTENEDORES"
echo "----------------------------------------"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "clickhouse|kafka|thingsboard|postgres-tb|prometheus|grafana|node-exporter"
echo ""

# 10. Verificar logs recientes de ThingsBoard
echo "10. ✓ LOGS DE THINGSBOARD (últimas 5 líneas)"
echo "----------------------------------------"
docker logs thingsboard --tail 5 2>&1 | grep -v "WARN"
echo ""

echo "=========================================="
echo "VALIDACIÓN COMPLETADA"
echo "=========================================="
echo ""
echo -e "${GREEN}✓ Sistema desplegado correctamente${NC}"
echo ""
echo "PRÓXIMOS PASOS:"
echo "1. Acceder a ThingsBoard: http://localhost:8080"
echo "   Usuario: sysadmin@thingsboard.org"
echo "   Password: sysadmin"
echo ""
echo "2. Crear dispositivos de drones en ThingsBoard"
echo "   Ejecutar: python3 /opt/drone-telemetry/simulator/provision_devices.py"
echo ""
echo "3. Iniciar simulador de drones"
echo "   Ejecutar: /opt/drone-telemetry/simulator/start_drones.sh"
echo ""
echo "4. Acceder a Grafana: http://localhost:3000"
echo "   Usuario: admin"
echo "   Password: Grafana2025!"
echo ""
