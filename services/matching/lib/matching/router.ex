defmodule Matching.Router do
  # "use Plug.Router" trae todas las macros necesarias para definir rutas web (get, post, etc.)
  use Plug.Router

  # ==========================================
  # PIPELINE (Tubería de ejecución)
  # ==========================================
  # Los "plugs" se ejecutan en orden, de arriba a abajo, para cada petición que llega.

  # 1. Primero, leemos el cuerpo de la petición. Si es un JSON, usamos la librería "Jason" para decodificarlo.
  plug Plug.Parsers, parsers: [:json], pass: ["application/json"], json_decoder: Jason

  # 2. Intentamos emparejar la URL de la petición con las rutas que definimos abajo.
  plug :match

  # 3. Finalmente, ejecutamos el código de la ruta correspondiente.
  plug :dispatch

  # ==========================================
  # ENDPOINTS (Rutas)
  # ==========================================

  # Endpoint de Healthcheck
  get "/health" do
    # En Elixir, los diccionarios se llaman "Maps" y se definen con %{clave: valor}
    respuesta = %{status: "ok", service: "matching"}

    # El Pipe Operator (|>) es una forma de pasar el resultado de una función como argumento de la siguiente.
    # Coge el objeto "conn" (la conexión HTTP) y se lo pasa a la siguiente función.
    # El resultado de esa función se pasa a la siguiente, y así sucesivamente.
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(respuesta))
  end

  # Endpoint principal: POST /match
  # Aquí simularemos que encontramos un conductor.
  post "/match" do
    # 1. Simulamos la lógica de emparejamiento (simplificado)
    respuesta = %{
      status: "success",
      message: "Pasajero emparejado exitosamente",
      driver_id: "driver-42",
      estimated_distance_km: 5.5
    }

    # 2. Preparamos y enviamos la respuesta HTTP
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(respuesta))
  end

  # ==========================================
  # RUTAS NO ENCONTRADAS (Catch-all)
  # ==========================================
  # Si alguien hace una petición a una ruta que no existe (ej. /hola), cae aquí.
  match _ do
    send_resp(conn, 404, "Ruta no encontrada")
  end
end
