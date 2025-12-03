#!/bin/bash
# Script para iniciar todos los servicios

echo "Iniciando todos los servicios..."

# Iniciar contenedores en orden
echo "Iniciando ClickHouse..."
docker start clickhouse 2>/dev/null || true

echo "Iniciando Zookeeper..."
docker start zookeeper 2>/dev/null || true

sleep 5

echo "Iniciando Kafka..."
docker start kafka 2>/dev/null || true

sleep 5

echo "Iniciando PostgreSQL..."
docker start postgres-tb 2>/dev/null || true

sleep 3

echo "Iniciando ThingsBoard..."
docker start thingsboard 2>/dev/null || true

echo "Iniciando Grafana..."
docker start grafana 2>/dev/null || true

echo "Iniciando Prometheus..."
docker start prometheus 2>/dev/null || true

echo "Iniciando Node Exporter..."
docker start node-exporter 2>/dev/null || true

echo "Iniciando Kafka Connect..."
docker start kafka-connect 2>/dev/null || true

echo ""
echo "✓ Servicios iniciados"
echo ""
echo "Esperando a que los servicios estén listos..."
sleep 10

echo "Para verificar el estado, ejecuta: ./scripts/verify-deployment.sh"
