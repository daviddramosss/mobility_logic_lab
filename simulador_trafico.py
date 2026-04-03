import requests
import time
import random 
import threading # Para hilos en segundo plano

URL = "http://localhost:8080/request-ride"
STATUS_URL = "http://localhost:8080/ride-status" 

# Esta función se ejecuta en la sombra y pregunta a Go por un viaje concreto
def esperar_viaje_en_cola(num_viaje, customer_id): 
    while True:
        time.sleep(2) # Preguntamos cada 2 segundos
        try:
            res = requests.get(f"{STATUS_URL}?id={customer_id}")
            if res.status_code == 200:
                data = res.json()
                conductor = data.get('driver_id', 'Desconocido')
                
                # Leemos los datos que Elixir acaba de calcular
                precio = data.get('pricing', {}).get('tarifa_final', 'N/A')
                distancia = data.get('trip_details', {}).get('distance_km', 'N/A')
                demanda = data.get('trip_details', {}).get('demand_factor', 'N/A')
                
                print(f"\n🎉 ¡ACTUALIZACIÓN! El Viaje #{num_viaje} sale de la cola -> {conductor} | Distancia: {distancia}km | Demanda: {demanda}x | Precio: {precio}\n")
                break # Terminamos el hilo
            elif res.status_code != 202:
                break # Si da error o 404, terminamos
        except:
            break

print("🚀 Iniciando simulación de tráfico con Polling Asíncrono...")
print("Presiona Ctrl+C para detener\n")

viajes_realizados = 0
try:
    while True:
        viajes_realizados += 1
        print(f"--- Solicitando Viaje #{viajes_realizados} ---")
        
        try:
            response = requests.post(URL)
            data = response.json() 
            estado_viaje = data.get('status')
            
            if estado_viaje == "confirmed":
                precio = data['pricing']['tarifa_final']
                conductor = data['driver_id']
                distancia = data['trip_details']['distance_km']
                demanda = data['trip_details'].get('demand_factor', 'N/A') 
                print(f"✅ ÉXITO: {conductor} asignado | Distancia: {distancia}km | Demanda: {demanda}x | Precio: {precio}")
            
            elif estado_viaje == "queued":
                posicion = data.get('queue_position', 'Desconocida')
                customer_id = data.get('customer_id') # Leemos el ID que nos manda Elixir
                
                print(f"⏳ EN COLA (Viaje #{viajes_realizados}): Conductores ocupados. Posición: {posicion}")
                
                # Lanzamos un hilo asíncrono para que vigile este viaje en concreto
                if customer_id:
                    threading.Thread(target=esperar_viaje_en_cola, args=(viajes_realizados, customer_id), daemon=True).start()
                
            else:
                print(f"❌ ERROR DESCONOCIDO: {data}")
                
        except Exception as e:
            print(f"FALLO DE PROCESAMIENTO: {e}")

        # ESTRÉS 
        tiempo_espera = random.uniform(0.5, 1)   
        time.sleep(tiempo_espera)

except KeyboardInterrupt:
    print(f"\n🛑 Simulación detenida. Total viajes procesados: {viajes_realizados}")