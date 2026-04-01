# Importamos la librería json para manejar los datos
require 'json'
# Importamos Sinatra
require 'sinatra'

# Configuramos Sinatra para que escuche en todas las interfaces de red (necesario para Docker)
set :bind, '0.0.0.0'
# Definimos el puerto en el que correrá (el 3000 es el estándar en Ruby)
set :port, 3000

# Endpoint de Healthcheck (igual que hicimos en Go)
# Fíjate en la sintaxis: "get '/ruta' do ... end"
get '/health' do
  # Indicamos que la respuesta será un JSON
  content_type :json
  
  # En Ruby, la última línea de un bloque se devuelve (return) automáticamente.
  # El método .to_json convierte un diccionario (Hash en Ruby) a texto JSON.
  { status: 'ok', service: 'pricing' }.to_json
end

# NUEVO ENDPOINT: POST /fare
# Recibe los datos del viaje y calcula el precio dinámico
post '/fare' do
  # 1. Le decimos al cliente que vamos a responder en formato JSON
  content_type :json

  begin
    # 2. Leemos el JSON que nos llega en el cuerpo (body) de la petición HTTP
    # En Ruby, request.body.read lee el texto en crudo, y JSON.parse lo convierte a un Hash (diccionario)
    payload = JSON.parse(request.body.read)

    # 3. Extraemos las variables (usamos .to_f para asegurarnos de que sean números decimales o floats)
    distance_km = payload['distance_km'].to_f
    duration_min = payload['duration_min'].to_f
    demand_factor = payload['demand_factor'].to_f || 1.0 # Si no mandan demanda, asumimos 1.0 (normal)

    # 4. LÓGICA DE NEGOCIO
    # Definimos las tarifas base simuladas de Cabify
    base_price = 1.50         # Precio por solicitar el servicio
    price_per_km = 1.05       # Precio por kilómetro recorrido
    price_per_min = 0.15      # Precio por minuto de trayecto

    # Calculamos la tarifa estándar
    tarifa_estandar = base_price + (distance_km * price_per_km) + (duration_min * price_per_min)

    # Aplicamos la estrategia dinámica (multiplicamos por la demanda)
    tarifa_final = tarifa_estandar * demand_factor

    # 5. Preparamos la respuesta, redondeando a 2 decimales (.round(2))
    response_data = {
      status: 'success',
      distancia_km: distance_km,
      demanda: demand_factor,
      tarifa_estandar: tarifa_estandar.round(2),
      tarifa_final: tarifa_final.round(2),
      moneda: 'EUR'
    }

    # 6. Devolvemos el JSON final
    response_data.to_json

  rescue => e
    # Si alguien manda un JSON mal formado, capturamos el error (rescue) y devolvemos un código 400
    status 400
    { status: 'error', message: 'Datos inválidos', details: e.message }.to_json
  end
end

puts "💰 Pricing Service (Ruby) arrancando en el puerto 3000..."

