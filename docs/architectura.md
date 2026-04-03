# Estructura del Proyecto y Justificación Tecnológica

La estructura de carpetas sigue un enfoque de **Arquitectura Orientada a Servicios (SOA)**. Cada microservicio está completamente aislado en su propia carpeta dentro de `/services`, lo que permite que cada uno escale, se compile y se despliegue de forma independiente utilizando el lenguaje más adecuado para su dominio (*Polyglot Persistence/Programming*).

## Justificación de Lenguajes
* **Go (Ingestion):** Elegido por su altísimo rendimiento en red, tipado fuerte y manejo de concurrencia nativa, ideal para un API Gateway que debe soportar miles de conexiones entrantes por segundo sin bloquearse.
* **Elixir (Matching):** Elegido por su máquina virtual (BEAM), diseñada específicamente para construir sistemas distribuidos, tolerantes a fallos y con un manejo del estado en memoria (GenServers) superior al de lenguajes tradicionales.
* **Ruby (Pricing):** Elegido por su velocidad de desarrollo y flexibilidad, ideal para reglas de negocio y motores de precios (*scripts* analíticos) que suelen cambiar con mucha frecuencia.

## Diccionario de Archivos Principales

### Raíz del proyecto
* **`docker-compose.yml`**: Archivo de orquestación de infraestructura. Define cómo se construyen, conectan y comunican por red los tres contenedores (Go, Elixir, Ruby).
* **`simular_trafico.py`**: Cliente de pruebas (Test Suite). Genera estrés asíncrono sobre el servidor y maneja hilos en segundo plano (*polling*) para simular el comportamiento de múltiples aplicaciones móviles.

### `/services/ingestion/` (API Gateway - Go)
* **`cmd/main.go`**: Punto de entrada de la aplicación Go. Levanta el servidor HTTP, define los endpoints públicos y actúa como *Reverse Proxy* hacia Elixir respetando los códigos de estado.
* **`internal/handler/location_handler.go`**: Controlador encargado de procesar la recepción de coordenadas GPS en tiempo real. Valida estrictamente que las peticiones sean `POST`, decodifica el JSON de forma segura y maneja los errores HTTP. Aísla la lógica de validación para mantener el `main.go` limpio.
* **`internal/model/location.go`**: Define los Modelos de Dominio (Data Transfer Objects) usando el tipado fuerte de Go. Las estructuras `Location` y `Response` actúan como un "contrato" estricto: aseguran que cualquier JSON malformado que envíe un móvil sea rechazado antes de que penetre en el resto de la arquitectura.
* **`go.mod`**: Gestor de dependencias y versiones del ecosistema Go.
* **`Dockerfile`**: Compila Go en un binario estático mediante un proceso *Multi-stage build* para crear una imagen Docker extremadamente ligera (basada en Alpine).


### `/services/matching/` (Orquestador - Elixir)
* **`lib/matching/application.ex`**: Archivo de arranque de Elixir. Define el árbol de supervisión principal, asegurándose de que si el servidor web o el Dispatcher fallan, se reinicien automáticamente.
* **`lib/matching/router.ex`**: Controlador HTTP interno de Elixir. Genera los datos simulados del viaje (distancia, demanda), comunica con el motor de Ruby y formatea el JSON final de respuesta.  
* **`lib/matching/dispatcher.ex`**: El núcleo de concurrencia (`GenServer`). Mantiene el estado en memoria de los conductores libres, gestiona la cola FIFO y maneja las asignaciones asíncronas de los viajes.
* **`mix.exs`**: Archivo de configuración de Mix, el gestor de dependencias y compilación de Elixir (equivalente a `package.json` en Node).
* **`Dockerfile`**: Instala las dependencias de Hex y compila el proyecto de Elixir para su ejecución en contenedor.

### `/services/pricing/` (Motor de Cálculo - Ruby)
* **`pricing_service.rb`**: Microservicio minimalista construido con Sinatra. Recibe las variables del viaje mediante POST y aplica las fórmulas matemáticas de precios dinámicos para devolver la tarifa final.
* **`Gemfile`**: Define las dependencias de Ruby (como Sinatra) y sus versiones. 
* **`Dockerfile`**: Instala las dependencias de Ruby y compila el proyecto de Elixir para su ejecución en contenedor.