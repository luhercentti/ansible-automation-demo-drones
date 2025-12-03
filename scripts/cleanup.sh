#!/bin/bash
# Script de cleanup completo

echo "========================================="
echo "ADVERTENCIA: Esto eliminará TODOS los datos"
echo "========================================="
echo ""
read -p "¿Estás seguro? (escribe 'SI' para continuar): " confirm

if [ "$confirm" != "SI" ]; then
    echo "Operación cancelada"
    exit 0
fi

echo ""
echo "Deteniendo servicios..."
sudo systemctl stop drone-simulator 2>/dev/null || true

echo "Eliminando contenedores..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "Eliminando volúmenes Docker..."
docker volume prune -f

echo "Eliminando red Docker..."
docker network rm drone_network 2>/dev/null || true

echo "Eliminando datos persistentes..."
sudo rm -rf /opt/drone-telemetry

echo "Eliminando servicio systemd..."
sudo rm -f /etc/systemd/system/drone-simulator.service
sudo systemctl daemon-reload

echo ""
echo "✓ Cleanup completo"
echo ""
echo "Para volver a desplegar, ejecuta:"
echo "  ansible-playbook -i inventory/hosts.yml site.yml"
