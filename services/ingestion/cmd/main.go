package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
)

func main() {
	port := ":8080"

	// 1. Endpoint de Healthcheck (El pulso del servicio)
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"status": "ok", "service": "ingestion"}`))
	})

	// 2. ENDPOINT PRINCIPAL: /request-ride
	// Este es el punto de entrada para que el usuario pida un Cabify
	http.HandleFunc("/request-ride", func(w http.ResponseWriter, r *http.Request) {
		log.Println("Go: Solicitud de viaje recibida. Contactando con el Orquestador (Elixir)...")

		// Llamada interna a Elixir usando el nombre del servicio en Docker
		// No enviamos body por ahora para simplificar, Elixir ya tiene datos simulados
		resp, err := http.Post("http://matching:4000/match", "application/json", nil)
		if err != nil {
			log.Printf("❌ Error al contactar con Elixir: %v", err)
			http.Error(w, "Servicio de Matching no disponible", http.StatusServiceUnavailable)
			return
		}
		defer resp.Body.Close()

		// Leemos la respuesta que viene de Elixir (que a su vez trae lo de Ruby)
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			http.Error(w, "Error leyendo respuesta de Elixir", http.StatusInternalServerError)
			return
		}

		// Enviamos la respuesta final al usuario
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode) // Envio el código de estado real que dio Elixir (200, 202, etc.)
		w.Write(body)

		log.Println("Go: Ciclo de petición finalizado. Respuesta enviada al cliente.")
	})

	// =========================================================================
	// 3. ENDPOINT: Consultar estado de la cola (Polling Asíncrono)
	// =========================================================================
	http.HandleFunc("/ride-status", func(w http.ResponseWriter, r *http.Request) {
		// Leemos el id de la URL que nos manda Python (ej: ?id=user-1234)
		customerID := r.URL.Query().Get("id")

		// Hacemos una petición GET al nuevo endpoint dinámico de Elixir
		resp, err := http.Get("http://matching:4000/match/" + customerID)
		if err != nil {
			log.Printf("❌ Error al consultar estado en Elixir: %v", err)
			http.Error(w, "Error contactando al orquestador", http.StatusServiceUnavailable)
			return
		}
		defer resp.Body.Close()

		// Leemos la respuesta
		body, _ := io.ReadAll(resp.Body)

		// Reenviamos exactamente el código HTTP y el JSON de Elixir a Python
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode) // Propagamos 200 (asignado), 202 (sigue en cola) o 404 (no existe)
		w.Write(body)
	})

	fmt.Printf("🚀 Ingestion Service (Go) escuchando en el puerto %s...\n", port)

	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Error al iniciar el servidor: %v", err)
	}
}
