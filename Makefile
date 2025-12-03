.PHONY: help install deploy verify start stop restart clean update backup test

# Variables
INVENTORY = inventory/hosts.yml
PLAYBOOK = site.yml
PYTHON = python3

# Colores para output
GREEN = \033[0;32m
YELLOW = \033[1;33m
NC = \033[0m # No Color

help: ## Mostrar esta ayuda
	@echo "Uso: make [target]"
	@echo ""
	@echo "Targets disponibles:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

check-ansible: ## Verificar que Ansible está instalado
	@which ansible-playbook > /dev/null || (echo "$(YELLOW)Ansible no está instalado. Instalando...$(NC)" && sudo apt update && sudo apt install -y ansible)
	@echo "$(GREEN)✓$(NC) Ansible instalado: $$(ansible --version | head -1)"

check-requirements: check-ansible ## Verificar todos los requisitos
	@echo "Verificando requisitos del sistema..."
	@$(PYTHON) --version || (echo "$(YELLOW)Python 3 requerido$(NC)" && exit 1)
	@docker --version || (echo "$(YELLOW)Docker será instalado por Ansible$(NC)")
	@echo "$(GREEN)✓$(NC) Requisitos básicos cumplidos"

install: check-requirements ## Alias para deploy
	@$(MAKE) deploy

deploy: check-ansible ## Desplegar todo el sistema
	@echo "$(GREEN)Desplegando sistema de telemetría de drones...$(NC)"
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK)
	@echo ""
	@echo "$(GREEN)=========================================$(NC)"
	@echo "$(GREEN)Despliegue completado!$(NC)"
	@echo "$(GREEN)=========================================$(NC)"
	@$(MAKE) info

deploy-local: check-ansible ## Desplegar en localhost
	@echo "$(GREEN)Desplegando en localhost...$(NC)"
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --connection=local

deploy-common: check-ansible ## Desplegar solo prerequisitos
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "common"

deploy-clickhouse: check-ansible ## Desplegar solo ClickHouse
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "clickhouse"

deploy-kafka: check-ansible ## Desplegar solo Kafka
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "kafka"

deploy-thingsboard: check-ansible ## Desplegar solo ThingsBoard
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "thingsboard"

deploy-monitoring: check-ansible ## Desplegar solo monitoreo
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "monitoring"

deploy-simulator: check-ansible ## Desplegar solo simulador
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --tags "simulator"

verify: ## Verificar estado del despliegue
	@echo "$(GREEN)Verificando despliegue...$(NC)"
	@bash scripts/verify-deployment.sh

start: ## Iniciar todos los servicios
	@echo "$(GREEN)Iniciando servicios...$(NC)"
	@bash scripts/start-all.sh

stop: ## Detener todos los servicios
	@echo "$(YELLOW)Deteniendo servicios...$(NC)"
	@bash scripts/stop-all.sh

restart: stop start ## Reiniciar todos los servicios

provision-devices: ## Provisionar dispositivos en ThingsBoard
	@echo "$(GREEN)Provisionando dispositivos drones...$(NC)"
	@$(PYTHON) /opt/drone-telemetry/drone-simulator/provision_devices.py

start-drones: ## Iniciar simulador de drones
	@echo "$(GREEN)Iniciando simulador de drones...$(NC)"
	@/opt/drone-telemetry/drone-simulator/start_drones.sh

setup-kafka-connect: ## Configurar Kafka Connect para ClickHouse
	@echo "$(GREEN)Configurando Kafka Connect...$(NC)"
	@$(PYTHON) scripts/setup-kafka-connect.py

update: check-ansible ## Actualizar componentes del sistema
	@echo "$(GREEN)Actualizando sistema...$(NC)"
	ansible-playbook -i $(INVENTORY) update.yml

backup: ## Crear backup de datos
	@echo "$(GREEN)Creando backup...$(NC)"
	@bash scripts/backup.sh

clean: ## Limpiar contenedores y datos (PELIGROSO!)
	@echo "$(YELLOW)⚠️  ADVERTENCIA: Esto eliminará todos los datos$(NC)"
	@bash scripts/cleanup.sh

undeploy: check-ansible ## Eliminar completamente el despliegue
	@echo "$(YELLOW)Eliminando despliegue...$(NC)"
	ansible-playbook -i $(INVENTORY) undeploy.yml

test: verify ## Ejecutar tests de verificación
	@echo "$(GREEN)Ejecutando tests...$(NC)"
	@$(MAKE) verify

logs: ## Ver logs de todos los contenedores
	@echo "Contenedores en ejecución:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
	@echo ""
	@echo "Para ver logs de un contenedor específico:"
	@echo "  docker logs -f <container_name>"

logs-thingsboard: ## Ver logs de ThingsBoard
	@docker logs -f thingsboard

logs-kafka: ## Ver logs de Kafka
	@docker logs -f kafka

logs-clickhouse: ## Ver logs de ClickHouse
	@docker logs -f clickhouse

logs-grafana: ## Ver logs de Grafana
	@docker logs -f grafana

status: ## Mostrar estado de servicios
	@echo "$(GREEN)Estado de servicios Docker:$(NC)"
	@docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No hay contenedores"
	@echo ""
	@echo "$(GREEN)Uso de recursos:$(NC)"
	@docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}" 2>/dev/null || echo "No hay contenedores"

info: ## Mostrar información de acceso
	@echo ""
	@echo "$(GREEN)=========================================$(NC)"
	@echo "$(GREEN)URLs de Acceso:$(NC)"
	@echo "$(GREEN)=========================================$(NC)"
	@echo "  ThingsBoard:  http://localhost:8080"
	@echo "    Tenant:     tenant@thingsboard.org / tenant"
	@echo "    SysAdmin:   sysadmin@thingsboard.org / sysadmin"
	@echo ""
	@echo "  Grafana:      http://localhost:3000"
	@echo "    Credenciales: admin / Grafana2025!"
	@echo ""
	@echo "  Prometheus:   http://localhost:9090"
	@echo ""
	@echo "  ClickHouse:   http://localhost:8123"
	@echo "    User:       droneuser / ClickHouse2025!"
	@echo ""
	@echo "$(GREEN)=========================================$(NC)"
	@echo "$(GREEN)Comandos Útiles:$(NC)"
	@echo "$(GREEN)=========================================$(NC)"
	@echo "  make provision-devices  # Crear drones en ThingsBoard"
	@echo "  make start-drones      # Iniciar simulación"
	@echo "  make verify            # Verificar estado"
	@echo "  make status            # Ver recursos"
	@echo "  make logs              # Ver logs"
	@echo ""

shell-clickhouse: ## Abrir shell de ClickHouse
	@docker exec -it clickhouse clickhouse-client

shell-kafka: ## Abrir shell de Kafka
	@docker exec -it kafka bash

shell-thingsboard: ## Abrir shell de ThingsBoard
	@docker exec -it thingsboard bash

query-drones: ## Consultar datos de drones en ClickHouse
	@docker exec clickhouse clickhouse-client --query="SELECT drone_id, argMax(battery_level, timestamp) as battery, argMax(status, timestamp) as status, max(timestamp) as last_update FROM drone_telemetry.telemetry_data WHERE timestamp > now() - INTERVAL 10 MINUTE GROUP BY drone_id ORDER BY drone_id"

check-kafka-topic: ## Verificar mensajes en Kafka
	@docker exec kafka kafka-console-consumer --bootstrap-server localhost:9092 --topic drone-telemetry --from-beginning --max-messages 5

docs: ## Abrir documentación en navegador
	@echo "Abriendo documentación..."
	@open README.md 2>/dev/null || xdg-open README.md 2>/dev/null || echo "Ver README.md manualmente"

all: deploy verify info ## Desplegar y verificar todo
