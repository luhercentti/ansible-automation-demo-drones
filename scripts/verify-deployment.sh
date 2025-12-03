#!/bin/bash
# Script de verificación del despliegue

set -e

echo "========================================="
echo "Verificando Despliegue del Sistema"
echo "========================================="
echo ""

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_service() {
    local service_name=$1
    local port=$2
    local host=${3:-localhost}
    
    if docker ps | grep -q "$service_name"; then
        echo -e "${GREEN}✓${NC} $service_name está corriendo"
        
        if nc -z $host $port 2>/dev/null; then
            echo -e "${GREEN}✓${NC} Puerto $port está abierto"
        else
            echo -e "${YELLOW}⚠${NC} Puerto $port no está accesible"
        fi
    else
        echo -e "${RED}✗${NC} $service_name NO está corriendo"
        return 1
    fi
    echo ""
}

echo "1. Verificando contenedores Docker..."
echo "---------------------------------------"
check_service "clickhouse" 8123
check_service "kafka" 9092
check_service "thingsboard" 8080
check_service "postgres-tb" 5432
check_service "grafana" 3000
check_service "prometheus" 9090

echo "2. Verificando ClickHouse..."
echo "---------------------------------------"
if docker exec clickhouse clickhouse-client --query="SELECT 1" &>/dev/null; then
    echo -e "${GREEN}✓${NC} ClickHouse responde a consultas"
    
    DB_EXISTS=$(docker exec clickhouse clickhouse-client --query="SHOW DATABASES" | grep -c "drone_telemetry" || true)
    if [ "$DB_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Base de datos 'drone_telemetry' existe"
    else
        echo -e "${RED}✗${NC} Base de datos 'drone_telemetry' NO existe"
    fi
else
    echo -e "${RED}✗${NC} ClickHouse no responde"
fi
echo ""

echo "3. Verificando Kafka..."
echo "---------------------------------------"
if docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 &>/dev/null; then
    echo -e "${GREEN}✓${NC} Kafka responde"
    
    TOPIC_EXISTS=$(docker exec kafka kafka-topics --list --bootstrap-server localhost:9092 | grep -c "drone-telemetry" || true)
    if [ "$TOPIC_EXISTS" -gt 0 ]; then
        echo -e "${GREEN}✓${NC} Topic 'drone-telemetry' existe"
    else
        echo -e "${YELLOW}⚠${NC} Topic 'drone-telemetry' NO existe"
    fi
else
    echo -e "${RED}✗${NC} Kafka no responde"
fi
echo ""

echo "4. Verificando ThingsBoard..."
echo "---------------------------------------"
if curl -s http://localhost:8080/login > /dev/null; then
    echo -e "${GREEN}✓${NC} ThingsBoard UI accesible"
else
    echo -e "${RED}✗${NC} ThingsBoard UI NO accesible"
fi
echo ""

echo "5. Verificando Grafana..."
echo "---------------------------------------"
if curl -s http://localhost:3000/api/health | grep -q "ok"; then
    echo -e "${GREEN}✓${NC} Grafana está saludable"
else
    echo -e "${RED}✗${NC} Grafana NO está saludable"
fi
echo ""

echo "6. Verificando Prometheus..."
echo "---------------------------------------"
if curl -s http://localhost:9090/-/healthy | grep -q "Prometheus"; then
    echo -e "${GREEN}✓${NC} Prometheus está saludable"
else
    echo -e "${RED}✗${NC} Prometheus NO está saludable"
fi
echo ""

echo "========================================="
echo "Verificación Completa"
echo "========================================="
echo ""
echo "URLs de Acceso:"
echo "  ThingsBoard: http://localhost:8080"
echo "  Grafana:     http://localhost:3000"
echo "  Prometheus:  http://localhost:9090"
echo ""
