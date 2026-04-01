defmodule Matching.Router do
  # "use Plug.Router" trae todas las macros necesarias para definir rutas web (get, post, etc.)
  use Plug.Router

  # ==========================================
  # PIPELINE (Tubería de ejecución)
  # ==========================================
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :match
  plug :dispatch

  # ==========================================
  # ENDPOINTS (Rutas)
  # ==========================================

  # Endpoint de Healthcheck
  get "/health" do
    respuesta = %{status: "ok", service: "matching"}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(respuesta))
  end

  # ==========================================
  # Endpoint principal: POST /match (EL ORQUESTADOR)
  # ==========================================
  post "/match" do
    # 1. Simulamos los datos de un viaje que acabamos de "emparejar"
    distance = 5.5
    duration = 12.0
    demand = 1.2 # Simulamos que hay alta demanda (lluvia, hora punta...)

    # 2. Preparamos el paquete de datos para preguntarle el precio a Ruby
    payload = Jason.encode!(%{
      distance_km: distance,
      duration_min: duration,
      demand_factor: demand
    })

    # 3. Definimos la ruta interna de Docker hacia nuestro contenedor de Ruby
    # Como están en la misma red de Docker Compose, usamos el nombre del servicio "pricing"
    url = "http://pricing:3000/fare"
    headers = [{"Content-Type", "application/json"}]

    # 4. Hacemos la petición HTTP interna a Ruby y evaluamos la respuesta (Pattern Matching)
    case HTTPoison.post(url, payload, headers) do
      # PATRÓN 1: Ruby contesta correctamente con un código 200 OK
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        # Decodificamos el JSON que nos ha devuelto Ruby
        pricing_data = Jason.decode!(body)

        # Construimos el "Ticket Final" juntando nuestros datos de Elixir con los precios de Ruby
        respuesta_final = %{
          status: "success",
          message: "Pasajero emparejado y tarifa calculada con éxito",
          driver_id: "driver-42",
          trip_details: %{
            distance_km: distance,
            duration_min: duration
          },
          pricing: pricing_data # Anidamos la respuesta de Ruby aquí dentro
        }

        # Enviamos la respuesta final al usuario (app móvil)
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(respuesta_final))

      # PATRÓN 2: Cualquier otra cosa (Ruby caído, error 500, etc.)
      _ ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(500, Jason.encode!(%{error: "Error interno: El motor de precios no responde"}))
    end
  end

  # ==========================================
  # RUTAS NO ENCONTRADAS (Catch-all)
  # ==========================================
  match _ do
    send_resp(conn, 404, "Ruta no encontrada")
  end
end
