#!/bin/bash
# Script para detener todos los servicios

echo "Deteniendo todos los servicios..."

# Detener simulador si está corriendo
if systemctl is-active --quiet drone-simulator; then
    echo "Deteniendo simulador de drones..."
    sudo systemctl stop drone-simulator
fi

# Detener contenedores Docker
echo "Deteniendo contenedores Docker..."
docker stop $(docker ps -q) 2>/dev/null || true

echo "✓ Todos los servicios detenidos"
