#!/usr/bin/env python3
"""
Script para configurar Kafka Connect con ClickHouse Sink
"""
import requests
import json
import time
import sys

KAFKA_CONNECT_URL = "http://localhost:8083"
CONFIG_FILE = "/opt/drone-telemetry/config/kafka-connect-clickhouse.json"

def wait_for_connect():
    """Esperar a que Kafka Connect esté listo"""
    print("Esperando a que Kafka Connect esté disponible...")
    max_retries = 30
    for i in range(max_retries):
        try:
            response = requests.get(f"{KAFKA_CONNECT_URL}/")
            if response.status_code == 200:
                print("✓ Kafka Connect está listo")
                return True
        except requests.exceptions.RequestException:
            pass
        
        time.sleep(2)
        print(f"  Intento {i+1}/{max_retries}...")
    
    print("✗ Kafka Connect no está disponible")
    return False

def get_connectors():
    """Obtener lista de conectores existentes"""
    try:
        response = requests.get(f"{KAFKA_CONNECT_URL}/connectors")
        if response.status_code == 200:
            return response.json()
    except requests.exceptions.RequestException as e:
        print(f"Error al obtener conectores: {e}")
    return []

def create_connector(config):
    """Crear conector de ClickHouse"""
    try:
        # Primero, intentar eliminar si existe
        connector_name = config.get("name")
        existing = get_connectors()
        
        if connector_name in existing:
            print(f"Eliminando conector existente '{connector_name}'...")
            requests.delete(f"{KAFKA_CONNECT_URL}/connectors/{connector_name}")
            time.sleep(2)
        
        # Crear nuevo conector
        print(f"Creando conector '{connector_name}'...")
        response = requests.post(
            f"{KAFKA_CONNECT_URL}/connectors",
            headers={"Content-Type": "application/json"},
            json=config
        )
        
        if response.status_code in [200, 201]:
            print(f"✓ Conector '{connector_name}' creado exitosamente")
            return True
        else:
            print(f"✗ Error al crear conector: {response.text}")
            return False
            
    except requests.exceptions.RequestException as e:
        print(f"✗ Error de conexión: {e}")
        return False

def check_connector_status(connector_name):
    """Verificar estado del conector"""
    try:
        response = requests.get(f"{KAFKA_CONNECT_URL}/connectors/{connector_name}/status")
        if response.status_code == 200:
            status = response.json()
            print(f"\nEstado del conector '{connector_name}':")
            print(f"  Estado: {status['connector']['state']}")
            print(f"  Tareas: {len(status['tasks'])}")
            for i, task in enumerate(status['tasks']):
                print(f"    Task {i}: {task['state']}")
            return status['connector']['state'] == 'RUNNING'
    except requests.exceptions.RequestException as e:
        print(f"Error al verificar estado: {e}")
    return False

def main():
    # Esperar a Kafka Connect
    if not wait_for_connect():
        sys.exit(1)
    
    # Leer configuración
    try:
        with open(CONFIG_FILE, 'r') as f:
            config = json.load(f)
    except FileNotFoundError:
        print(f"✗ Archivo de configuración no encontrado: {CONFIG_FILE}")
        sys.exit(1)
    except json.JSONDecodeError as e:
        print(f"✗ Error al parsear JSON: {e}")
        sys.exit(1)
    
    # Crear conector
    if create_connector(config):
        time.sleep(3)
        check_connector_status(config["name"])
        print("\n✓ Configuración completada")
        print("\nPara verificar el flujo de datos:")
        print("  1. Inicia el simulador de drones")
        print("  2. Verifica datos en ThingsBoard")
        print("  3. Consulta ClickHouse:")
        print("     docker exec clickhouse clickhouse-client --query='SELECT count() FROM drone_telemetry.telemetry_data'")
    else:
        print("\n✗ Configuración falló")
        sys.exit(1)

if __name__ == "__main__":
    main()
