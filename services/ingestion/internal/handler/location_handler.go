package handler

import (
	"encoding/json"
	"fmt"
	"net/http"

	// Aquí importamos nuestro propio paquete.
	// Fíjate que usa el nombre del módulo que definimos en go.mod
	"mobility_logic_lab/ingestion/internal/model"
)

// HandleLocation procesa las peticiones entrantes de ubicación GPS
func HandleLocation(w http.ResponseWriter, r *http.Request) {
	// 1. Validar que solo aceptamos peticiones POST
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		json.NewEncoder(w).Encode(model.Response{
			Status:  "error",
			Message: "Método no permitido. Usa POST.",
		})
		return
	}

	// 2. Crear una variable vacía de nuestro modelo
	var loc model.Location

	// 3. Decodificar el JSON del cuerpo de la petición (Body) hacia nuestra variable
	// El símbolo '&' pasa el puntero de la variable para que Decode la rellene
	err := json.NewDecoder(r.Body).Decode(&loc)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		json.NewEncoder(w).Encode(model.Response{
			Status:  "error",
			Message: "JSON inválido o malformado",
		})
		return
	}

	// 4. (Simulación) Aquí en el futuro enviaríamos esto a un broker como Kafka o directamente a Elixir.
	// Por ahora, simplemente lo imprimimos en la consola del servidor para ver que funciona.
	fmt.Printf("[INGESTION] Recibida ubicación de %s (ID: %s) -> Lat: %f, Lng: %f\n", loc.Type, loc.ID, loc.Lat, loc.Lng)

	// 5. Responder al cliente que todo ha ido bien
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(model.Response{
		Status:  "success",
		Message: "Ubicación procesada correctamente",
	})
}
