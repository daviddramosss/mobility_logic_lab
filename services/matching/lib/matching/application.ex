# Definimos el módulo. Fíjate que el nombre coincide con la ruta de carpetas (Matching)
defmodule Matching.Application do
  # "use Application" le dice a Elixir: "Este módulo es el punto de arranque principal"
  use Application

  # La función start/2 es llamada automáticamente cuando arranca la aplicación.
  # Los guiones bajos (_type, _args) significan: "Sé que recibo estos argumentos, pero no los voy a usar".
  # Esto evita que el compilador de Elixir nos dé advertencias (warnings) de "variable no usada".
  def start(_type, _args) do
    # 'children' es una lista de todos los procesos (trabajadores) que queremos
    # que nuestro Supervisor vigile desde el momento en que arranca la app.
    children = [
      # 1. Levantamos el Dispatcher (GenServer) para gestionar conductores y colas.
      # Al estar aquí, si el Dispatcher falla, el Supervisor lo reiniciará automáticamente.
      Matching.Dispatcher,
      # Aquí le decimos que levante el servidor web (Cowboy) usando Plug.
      # Le indicamos que el esquema es HTTP, que el módulo que manejará las rutas
      # se llamará Matching.Router, y que escuche en el puerto 4000.
      {Plug.Cowboy, scheme: :http, plug: Matching.Router, options: [port: 4000]}
    ]

    # Configuramos el Supervisor.
    # La estrategia :one_for_one significa: "Si un hijo de la lista 'children' muere, reinicia SÓLO a ese hijo".
    opts = [strategy: :one_for_one, name: Matching.Supervisor]

    # Arrancamos el Supervisor con nuestra lista de hijos y configuraciones.
    Supervisor.start_link(children, opts)
  end
end
