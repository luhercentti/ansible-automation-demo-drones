# 📚 Documentación del Proyecto

Esta carpeta contiene documentación técnica adicional y recursos de referencia.

## Archivos

### `clickhouse-queries.sql`
Colección completa de consultas SQL útiles para ClickHouse, organizadas por:
- Consultas básicas
- Análisis de batería
- Análisis geoespacial
- Análisis temporal
- Detección de anomalías
- Optimización y mantenimiento

**Uso:**
```bash
# Ejecutar desde el cliente de ClickHouse
docker exec -it clickhouse clickhouse-client

# O desde archivo
docker exec clickhouse clickhouse-client < docs/clickhouse-queries.sql
```

## Recursos Adicionales

### Documentación Principal
- [README.md](../README.md) - Documentación completa del proyecto
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Arquitectura detallada del sistema
- [QUICKSTART.md](../QUICKSTART.md) - Guía de inicio rápido
- [EXAMPLES.md](../EXAMPLES.md) - Ejemplos de uso práctico
- [REQUIREMENTS.txt](../REQUIREMENTS.txt) - Requisitos del sistema

### Scripts
Ver carpeta `scripts/` para utilidades:
- Verificación de despliegue
- Inicio/parada de servicios
- Backup y restore
- Limpieza del sistema

### Configuración
Ver carpeta `config/` para:
- Kafka Connect configuration
- Monitoring setup
- Custom configurations

## Enlaces Útiles

- [ThingsBoard Documentation](https://thingsboard.io/docs/)
- [Apache Kafka Documentation](https://kafka.apache.org/documentation/)
- [ClickHouse Documentation](https://clickhouse.com/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Ansible Documentation](https://docs.ansible.com/)

## Contribuir

Para agregar nueva documentación:
1. Crea el archivo en esta carpeta
2. Actualiza este README
3. Referencia desde el README principal si es necesario
