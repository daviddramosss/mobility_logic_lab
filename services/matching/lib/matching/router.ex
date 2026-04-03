defmodule Matching.Router do
  use Plug.Router

  # Pipeline de ejecución
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason
  plug :match
  plug :dispatch

  # Healthcheck
  get "/health" do
    send_resp(conn, 200, Jason.encode!(%{status: "ok", service: "matching"}))
  end

  # ==========================================
  # Endpoint principal: POST /match
  # ==========================================
  post "/match" do
    # Generamos un ID de cliente para la simulación
    customer_id = "user-#{Enum.random(1000..9999)}"

    # 1. SOLICITUD AL DISPATCHER
    # Intentamos obtener un conductor real de nuestro pool de 5.
    case Matching.Dispatcher.request_ride(customer_id) do

      # CASO A: ¡Hay conductor disponible!
      {:ok, driver_id} ->
        # Generamos los datos del viaje
        distance = Float.round(:rand.uniform() * 18.0 + 2.0, 2)
        duration = Float.round(distance * Enum.random(2..4), 1)
        demand = Enum.random([1.0, 1.2, 1.5, 2.0])

        # Consultamos el precio a Ruby (Pricing Service)
        payload = Jason.encode!(%{
          distance_km: distance,
          duration_min: duration,
          demand_factor: demand
        })

        url = "http://pricing:3000/fare"
        headers = [{"Content-Type", "application/json"}]

        case HTTPoison.post(url, payload, headers) do
          {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
            pricing_data = Jason.decode!(body)

            respuesta_final = %{
              status: "confirmed",
              message: "Conductor asignado con éxito",
              driver_id: "driver-#{driver_id}", # El ID que nos dio el Dispatcher
              trip_details: %{
                distance_km: distance,
                duration_min: duration,
                demand_factor: demand
              },
              pricing: pricing_data
            }

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(respuesta_final))

          _ ->
            send_resp(conn, 500, Jason.encode!(%{error: "Error en el motor de precios"}))
        end

      # CASO B: No hay conductores (Cola FIFO)
      {:queued, position} ->
        respuesta_espera = %{
          status: "queued",
          customer_id: customer_id,
          message: "Todos nuestros conductores están realizando otros trayectos.",
          queue_position: position,
          estimated_wait: "Te avisaremos en cuanto un conductor quede libre."
        }

        conn
        |> put_resp_content_type("application/json")
        # Usamos 202 (Accepted) porque la petición es válida pero el viaje aún no se ha procesado
        |> send_resp(202, Jason.encode!(respuesta_espera))
    end
  end

  # ==========================================
  # Endpoint para consultar el estado (Polling)
  # ==========================================
  get "/match/:id" do
    case Matching.Dispatcher.check_status(id) do
      {:assigned, driver_id} ->
        send_resp(conn, 200, Jason.encode!(%{status: "confirmed", driver_id: "driver-#{driver_id}"}))
      :queued ->
        send_resp(conn, 202, Jason.encode!(%{status: "queued"}))
      :not_found ->
        send_resp(conn, 404, Jason.encode!(%{error: "Viaje finalizado o no existe"}))
  end
end

# ==========================================
  # RUTAS NO ENCONTRADAS (Catch-all)
  # ==========================================
  match _ do
    send_resp(conn, 404, "Ruta no encontrada")
  end
end
