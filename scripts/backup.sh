#!/bin/bash
# Backup de datos del sistema

BACKUP_DIR="/tmp/drone-telemetry-backup-$(date +%Y%m%d-%H%M%S)"
DATA_DIR="/opt/drone-telemetry/data"

echo "Creando backup en: $BACKUP_DIR"

mkdir -p "$BACKUP_DIR"

echo "Backup de ClickHouse..."
docker exec clickhouse clickhouse-client --query="BACKUP DATABASE drone_telemetry TO Disk('default', 'backup')" || true
cp -r "$DATA_DIR/clickhouse" "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup de Kafka..."
cp -r "$DATA_DIR/kafka" "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup de ThingsBoard..."
cp -r "$DATA_DIR/thingsboard" "$BACKUP_DIR/" 2>/dev/null || true

echo "Backup de Grafana..."
cp -r "$DATA_DIR/grafana" "$BACKUP_DIR/" 2>/dev/null || true

echo ""
echo "✓ Backup completado en: $BACKUP_DIR"
echo ""
echo "Para comprimir:"
echo "  tar -czf drone-backup.tar.gz -C $(dirname $BACKUP_DIR) $(basename $BACKUP_DIR)"
