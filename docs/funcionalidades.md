# Evolución Arquitectónica y Funcionalidades (Mobility-Logic Lab)

Este documento detalla el orden cronológico en el que se fueron implementando las funcionalidades del sistema, evolucionando desde un enrutador básico hasta una arquitectura distribuida, concurrente y asíncrona.

## 1. Arquitectura Base de Microservicios (Orquestación inicial)
Se estableció la topología de la red utilizando Docker Compose para comunicar tres microservicios independientes:
* **Ingestion (Go):** Actuando como API Gateway para recibir el tráfico externo.
* **Matching (Elixir):** Actuando como Orquestador principal de la lógica de la plataforma.
* **Pricing (Ruby):** Actuando como motor de cálculo aislado.
*Funcionalidad lograda:* Un flujo síncrono limpio donde Go recibe la petición, la pasa a Elixir, Elixir enriquece los datos simulando variables de viaje (distancia y duración) y consulta a Ruby para obtener un precio antes de responder al cliente.

## 2. Motor de Pricing Dinámico (Aplicación del TFG)
Se implementó en Ruby un algoritmo de *Dynamic Pricing* basado en el análisis de datos de mercado. Elixir genera multiplicadores de demanda simulados (1.0x, 1.2x, 1.5x, 2.0x) imitando condiciones del mundo real (ej. lluvia, salida de un concierto) y Ruby calcula la tarifa final basándose en el kilometraje, el tiempo y esta demanda.

## 3. Gestión de Estado y Concurrencia (Pool de Conductores)
Para hacer el sistema realista, se limitaron los recursos. Se implementó un `GenServer` en Elixir llamado `Dispatcher` que mantiene en memoria un "Pool" de 5 conductores disponibles. Al pedir un viaje, Elixir asigna un conductor, lo saca del pool y lanza un proceso asíncrono (`Task.start`) que simula el tiempo de viaje (5-15 segundos) en segundo plano antes de volver a liberar al conductor.

## 4. Implementación de Cola FIFO y Resiliencia
Se añadió lógica para manejar la saturación del sistema. Cuando los 5 conductores están ocupados, el `Dispatcher` de Elixir encola a los nuevos clientes en una lista FIFO (First-In-First-Out) y devuelve un código HTTP `202 Accepted` indicando la posición en la cola, en lugar de bloquear o tirar la conexión.

## 5. Refactorización del API Gateway (Transparencia HTTP)
Se corrigió un antipatrón en el servicio de Go. Inicialmente enmascaraba todas las respuestas con un código `200 OK`. Se refactorizó para que propague dinámicamente el `StatusCode` real de los microservicios subyacentes, respetando la semántica HTTP RESTful y permitiendo al cliente saber si su viaje fue confirmado (200) o encolado (202).

## 6. Patrón Asíncrono de Petición-Respuesta (Polling)
Se cerró el ciclo de vida de la petición implementando *Polling*. 
* Se añadió un registro en memoria de "viajes activos" en Elixir y un nuevo endpoint `GET /match/:id`.
* Se añadió un endpoint proxy en Go `GET /ride-status`.
* Se implementó *Background Threading* en el script de Python para que, al recibir un viaje encolado, lance un hilo secundario invisible que consulte periódicamente al servidor. Cuando Elixir asigna finalmente el conductor en segundo plano, Python detecta el cambio de estado y notifica al cliente en tiempo real.