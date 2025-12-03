# Guía de Contribución

¡Gracias por tu interés en contribuir a este proyecto! 🎉

## Cómo Contribuir

### Reportar Bugs

Si encuentras un bug, por favor:

1. Verifica que no esté ya reportado en [Issues](https://github.com/luhercentti/ansible-automation-demo-drones/issues)
2. Abre un nuevo issue con:
   - Descripción clara del problema
   - Pasos para reproducir
   - Comportamiento esperado vs. actual
   - Logs relevantes
   - Versión de Ubuntu, Ansible, Docker

### Sugerir Mejoras

Para sugerir nuevas características:

1. Abre un issue describiendo:
   - El problema que resuelve
   - Casos de uso
   - Implementación propuesta (opcional)

### Pull Requests

1. **Fork** el repositorio
2. **Crea una rama** para tu feature:
   ```bash
   git checkout -b feature/mi-nueva-caracteristica
   ```

3. **Desarrolla** siguiendo las convenciones del proyecto:
   - Usa YAML válido (espacios, no tabs)
   - Documenta nuevas variables en `group_vars/all.yml`
   - Agrega tareas a roles existentes o crea nuevos roles
   - Actualiza README.md si es necesario

4. **Prueba** tus cambios:
   ```bash
   # Verificar sintaxis YAML
   ansible-playbook --syntax-check site.yml
   
   # Modo dry-run
   ansible-playbook -i inventory/hosts.yml site.yml --check
   
   # Despliegue real en entorno de prueba
   ansible-playbook -i inventory/hosts.yml site.yml
   ```

5. **Commit** con mensajes descriptivos:
   ```bash
   git commit -m "feat: agregar soporte para autenticación Kafka"
   git commit -m "fix: corregir timeout en ThingsBoard"
   git commit -m "docs: actualizar guía de instalación"
   ```

6. **Push** a tu fork:
   ```bash
   git push origin feature/mi-nueva-caracteristica
   ```

7. **Abre un Pull Request** en GitHub

## Convenciones de Código

### Ansible

```yaml
# Bueno ✓
- name: Install required packages
  apt:
    name:
      - docker-ce
      - python3-pip
    state: present
    update_cache: yes

# Malo ✗ (sin nombre descriptivo, formato inconsistente)
- apt: name=docker-ce state=present
```

### Variables

```yaml
# Usar snake_case para variables
clickhouse_http_port: 8123
thingsboard_admin_email: "admin@example.com"

# No usar camelCase
clickHouseHttpPort: 8123  # ✗
```

### Estructura de Roles

```
roles/mi_rol/
├── defaults/
│   └── main.yml      # Variables por defecto
├── tasks/
│   └── main.yml      # Tareas principales
├── handlers/
│   └── main.yml      # Handlers (opcional)
├── templates/
│   └── config.j2     # Templates (opcional)
└── meta/
    └── main.yml      # Metadatos y dependencias
```

### Scripts Bash

```bash
#!/bin/bash
# Descripción del script

set -e  # Salir en error

# Variables
VARIABLE_NOMBRE="valor"

# Funciones
function mi_funcion() {
    echo "Haciendo algo..."
}

# Script principal
main() {
    mi_funcion
}

main "$@"
```

### Python

```python
#!/usr/bin/env python3
"""
Descripción del módulo
"""

# Imports estándar primero
import sys
import json

# Imports de terceros
import requests

# Constantes en MAYÚSCULAS
DEFAULT_PORT = 8080

def mi_funcion():
    """Docstring describiendo la función"""
    pass
```

## Testing

Antes de enviar un PR, verifica:

1. **Sintaxis Ansible:**
   ```bash
   ansible-playbook --syntax-check site.yml
   ```

2. **Ansible Lint** (recomendado):
   ```bash
   pip install ansible-lint
   ansible-lint site.yml
   ```

3. **Yamllint** (recomendado):
   ```bash
   pip install yamllint
   yamllint .
   ```

4. **Prueba funcional:**
   - Desplegar en entorno limpio
   - Ejecutar `make verify`
   - Verificar todos los componentes

## Áreas de Contribución

### Prioridad Alta
- [ ] Implementar autenticación Kafka (SASL/SSL)
- [ ] Kafka Connect Sink para ClickHouse automático
- [ ] Dashboards Grafana pre-configurados
- [ ] Tests automatizados con Molecule

### Prioridad Media
- [ ] Soporte para múltiples nodos (cluster mode)
- [ ] Alertas por Telegram/Slack
- [ ] Backup automatizado con cron
- [ ] Logs centralizados con ELK stack

### Prioridad Baja
- [ ] Soporte para otras distribuciones (CentOS, RHEL)
- [ ] Helm charts para Kubernetes
- [ ] Integración con Terraform
- [ ] CI/CD con GitHub Actions

## Documentación

Si agregas nuevas funcionalidades:

1. Actualiza `README.md` con instrucciones
2. Agrega ejemplos en `EXAMPLES.md`
3. Documenta arquitectura en `ARCHITECTURE.md` si aplica
4. Actualiza `CHANGELOG.md`

## Proceso de Review

Los maintainers revisarán tu PR considerando:

- ✅ Funcionalidad correcta
- ✅ Código limpio y documentado
- ✅ Tests pasando
- ✅ Sin romper funcionalidad existente
- ✅ Documentación actualizada

## Código de Conducta

- Sé respetuoso y profesional
- Acepta críticas constructivas
- Enfócate en lo mejor para el proyecto
- Ayuda a otros contribuidores

## Licencia

Al contribuir, aceptas que tus contribuciones serán licenciadas bajo la licencia MIT del proyecto.

## Preguntas

Si tienes dudas:

- Abre un issue con la etiqueta `question`
- Contacta a los maintainers

---

¡Gracias por contribuir! 🚀
