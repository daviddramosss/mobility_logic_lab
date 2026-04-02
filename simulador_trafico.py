import requests
import time
import json
import random 

# La URL de nuestro punto de entrada (Go)
URL = "http://localhost:8080/request-ride"

print("🚀 Iniciando simulación de tráfico en Mobility-Logic Lab...")
print("Presiona Ctrl+C para detener\n")

viajes_realizados = 0

try:
    while True:
        viajes_realizados += 1
        print(f"--- Solicitando Viaje #{viajes_realizados} ---")
        
        try:
            # Enviamos la petición a Go
            response = requests.post(URL)
            
            if response.status_code == 200:
                data = response.json()
                precio = data['pricing']['tarifa_final']
                conductor = data['driver_id']
                distancia = data['trip_details']['distance_km']
                demanda = data['pricing'].get('demand_factor', 'N/A')
                print(f"✅ ÉXITO: {conductor} asignado | Distancia: {distancia}km | Demanda: {demanda}x | Precio: {precio}€")
            
            elif response.status_code == 202: # Manejamos el caso de que estemos en la cola de Elixir   
                data = response.json()
                posicion = data.get('queue_position', 'Desconocida')
                print(f"⏳ EN COLA: Conductores ocupados. Tu posición en la espera: {posicion}")
            else:
                print(f"❌ ERROR: El sistema respondió con código {response.status_code}")
                
        except Exception as e:
            print(f"FALLO DE RED: {e}")

        # Esperamos entre 4 y 10 segundos para pedir un viaje
        tiempo_espera = random.randint(4, 10)   
        print(f"Esperando {tiempo_espera} segundos para la siguiente petición...\n")
        time.sleep(tiempo_espera)

except KeyboardInterrupt:
    print(f"\n🛑 Simulación detenida. Total viajes procesados: {viajes_realizados}")