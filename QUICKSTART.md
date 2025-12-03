# Guía de Inicio Rápido

Este es un resumen ejecutivo para desplegar el sistema rápidamente.

## Pre-requisitos

- Ubuntu 22.04 LTS
- 8 GB RAM mínimo
- Ansible 2.15+

## Instalación en 3 Pasos

### 1. Clonar e instalar Ansible

```bash
git clone https://github.com/luhercentti/ansible-automation-demo-drones.git
cd ansible-automation-demo-drones
sudo apt update && sudo apt install -y ansible
```

### 2. Desplegar

```bash
ansible-playbook -i inventory/hosts.yml site.yml
```

### 3. Iniciar simulador

```bash
# Provisionar dispositivos en ThingsBoard
python3 /opt/drone-telemetry/drone-simulator/provision_devices.py

# Iniciar drones
/opt/drone-telemetry/drone-simulator/start_drones.sh
```

## Acceso a Interfaces

- **ThingsBoard**: http://localhost:8080 (tenant@thingsboard.org / tenant)
- **Grafana**: http://localhost:3000 (admin / Grafana2025!)
- **Prometheus**: http://localhost:9090

## Verificar

```bash
./scripts/verify-deployment.sh
```

## ¿Problemas?

Ver sección [Troubleshooting](README.md#-troubleshooting) en el README principal.
