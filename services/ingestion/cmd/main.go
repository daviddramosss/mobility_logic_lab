package main

import (
	"fmt"      //Para imprimir por consola
	"log"      //Para manejar errores
	"net/http" //Para manejar peticiones HTTP
	// Importamos nuestro paquete handler
	"mobility_logic_lab/ingestion/internal/handler"
)

func main() {
	//Definimos el puerto en el que va a escuchar el servidor
	port := ":8080"

	// 2. Configuramos las rutas (endpoints)
	// Definimos un "healthcheck" básico para comprobar que el servidor está vivo.
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status": "ok", "service": "ingestion"}`))
	})

	// Registrar la ruta para recibir localizaciones y procesarlas usando nuestro handler
	http.HandleFunc("/location", handler.HandleLocation)

	//3. Mensaje para dar feedback
	fmt.Printf("Ingestion Service arrancando en el puerto %s...\n", port)

	//4. Inicio el servidor HTTP
	// ListenAndServe bloquea el hilo principal y se queda escuchando peticiones de red
	//Abre el puerto 8080 y se queda escuchando infinitamente en un bucle esperando peticiones.
	if err := http.ListenAndServe(port, nil); err != nil {
		log.Fatalf("Error al iniciar el servidor: %v", err)
	}
}
