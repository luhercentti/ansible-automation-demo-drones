#!/bin/bash
# Script para verificar recursos del sistema antes del despliegue

set -e

# Colores
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Verificando Recursos del Sistema"
echo "========================================="
echo ""

# Verificar RAM
TOTAL_RAM=$(free -m | awk '/^Mem:/{print $2}')
FREE_RAM=$(free -m | awk '/^Mem:/{print $7}')

echo -n "RAM Total: ${TOTAL_RAM}MB - "
if [ "$TOTAL_RAM" -lt 4096 ]; then
    echo -e "${YELLOW}⚠ Advertencia: Se recomienda mínimo 8GB RAM${NC}"
    echo "  Con menos de 8GB, algunos componentes pueden fallar"
    echo "  Considera usar una instancia más grande (t3.large o superior)"
else
    echo -e "${GREEN}✓ OK${NC}"
fi

echo -n "RAM Disponible: ${FREE_RAM}MB - "
if [ "$FREE_RAM" -lt 2048 ]; then
    echo -e "${RED}✗ Insuficiente RAM disponible${NC}"
    echo "  Se necesitan al menos 2GB libres"
    exit 1
else
    echo -e "${GREEN}✓ OK${NC}"
fi

# Verificar CPU
CPU_CORES=$(nproc)
echo -n "CPU Cores: $CPU_CORES - "
if [ "$CPU_CORES" -lt 2 ]; then
    echo -e "${YELLOW}⚠ Advertencia: Se recomienda mínimo 4 cores${NC}"
else
    echo -e "${GREEN}✓ OK${NC}"
fi

# Verificar Disco
DISK_FREE=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
echo -n "Disco Libre: ${DISK_FREE}GB - "
if [ "$DISK_FREE" -lt 20 ]; then
    echo -e "${RED}✗ Espacio insuficiente${NC}"
    echo "  Se necesitan al menos 20GB libres"
    exit 1
else
    echo -e "${GREEN}✓ OK${NC}"
fi

echo ""
echo "========================================="
echo -e "${GREEN}Recursos suficientes para desplegar${NC}"
echo "========================================="
echo ""

# Mostrar recomendaciones según recursos
if [ "$TOTAL_RAM" -lt 8192 ]; then
    echo -e "${YELLOW}RECOMENDACIÓN:${NC}"
    echo "Tu sistema tiene menos de 8GB RAM."
    echo "Para mejorar el rendimiento:"
    echo "  1. Usa una instancia t3.large (8GB) o superior"
    echo "  2. O desactiva el monitoreo: edita group_vars/all.yml"
    echo "     use_monitoring: false"
    echo ""
fi

exit 0
