defmodule Matching.Dispatcher do
  use GenServer

  # ===========================================================================
  # API del Cliente (Las funciones que llamará tu controlador web/router)
  # ===========================================================================


  # Inicia el Dispatcher con 5 conductores libres y la cola vacía.

  def start_link(_) do
    initial_state = %{
      drivers: [1, 2, 3, 4, 5],
      queue: []
    }
    # Registramos el proceso con el nombre del módulo para llamarlo fácilmente
    GenServer.start_link(__MODULE__, initial_state, name: __MODULE__)
  end


  # Un usuario pide un viaje. Es una llamada síncrona (espera respuesta).

  def request_ride(customer_id) do
    GenServer.call(__MODULE__, {:request_ride, customer_id})
  end


  # Un conductor avisa de que ha terminado. Es asíncrona (no bloquea al conductor).

  def free_driver(driver_id) do
    GenServer.cast(__MODULE__, {:free_driver, driver_id})
  end

  # ===========================================================================
  # Callbacks del Servidor (La lógica interna que maneja el estado)
  # ===========================================================================

  @impl true
  def init(state) do
    IO.puts("Dispatcher iniciado con estado: #{inspect(state)}")
    {:ok, state}
  end

  # --- Caso 1: Alguien pide un viaje ---
  @impl true
  def handle_call({:request_ride, customer_id}, _from, state) do
    case state.drivers do
      # Patrón: Hay al menos un conductor en la lista
      [driver | remaining_drivers] ->
        simulate_ride(driver, customer_id)

        # Actualizamos el estado quitando al conductor de la lista
        new_state = %{state | drivers: remaining_drivers}

        # Devolvemos {:reply, respuesta_al_cliente, nuevo_estado}
        {:reply, {:ok, driver}, new_state}

      # Patrón: La lista de conductores está vacía
      [] ->
        # Añadimos al cliente al final de la cola (FIFO)
        new_queue = state.queue ++ [customer_id]
        new_state = %{state | queue: new_queue}

        {:reply, {:queued, length(new_queue)}, new_state}
    end
  end

  # --- Caso 2: Un conductor queda libre ---
  @impl true
  def handle_cast({:free_driver, driver_id}, state) do
    case state.queue do
      # Patrón: Hay clientes esperando en la cola
      [next_customer | remaining_queue] ->
        # Asignamos automáticamente al primer cliente de la cola
        simulate_ride(driver_id, next_customer)

        new_state = %{state | queue: remaining_queue}
        {:noreply, new_state}

      # Patrón: Nadie está esperando
      [] ->
        # El conductor vuelve a la bolsa de disponibles
        new_state = %{state | drivers: [driver_id | state.drivers]}
        {:noreply, new_state}
    end
  end

  # ===========================================================================
  # Funciones Auxiliares Privadas
  # ===========================================================================

  defp simulate_ride(driver_id, customer_id) do
    # Usamos Task.start para lanzar un proceso independiente en background.
    # Así el Dispatcher queda libre instantáneamente para recibir más peticiones.
    Task.start(fn ->
      travel_time = Enum.random(5000..15000) # El viaje dura entre 5 y 15 segundos

      IO.puts("🚕 [VIAJE INICIADO] Conductor #{driver_id} asignado a Cliente #{customer_id} (Duración estimada: #{div(travel_time, 1000)}s)")

      # Simulamos el tiempo del viaje
      Process.sleep(travel_time)

      IO.puts("✅ [VIAJE TERMINADO] Conductor #{driver_id} dejó al Cliente #{customer_id}. Liberando conductor...")

      # Cuando termina, se llama a sí mismo para liberar al conductor
      Matching.Dispatcher.free_driver(driver_id)
    end)
  end
end
