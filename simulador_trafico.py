import requests
import time
import json

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
                demanda = data['trip_details']['demand_factor'] 
                print(f"✅ ÉXITO: {conductor} asignado | Distancia: {distancia}km | Demanda: {demanda}x | Precio: {precio}€")
            else:
                print(f"❌ ERROR: El sistema respondió con código {response.status_code}")
                
        except Exception as e:
            print(f"FALLO DE RED: {e}")

        # Esperamos 2 segundos entre peticiones para que se vean bien los logs
        time.sleep(2)

except KeyboardInterrupt:
    print(f"\n🛑 Simulación detenida. Total viajes procesados: {viajes_realizados}")