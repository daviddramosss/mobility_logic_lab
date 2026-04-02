# Mobility Logic Lab 🚖

Una prueba de concepto (PoC) de microservicios que simula el motor logístico principal de una plataforma de transporte compartido. Construido para explorar el diseño de sistemas distribuidos utilizando **Go, Elixir y Ruby** — el stack principal de Cabify.

Este proyecto es intencionadamente simple. El objetivo no es tener todas las funcionalidades, sino demostrar razonamiento arquitectónico, principios de código limpio y la capacidad de entender sistemas distribuidos a través de múltiples lenguajes de ejecución. 

### Resumen de la Arquitectura

```text
┌─────────────────────────────────────────────────────┐
│                 Simulador de Tráfico                │
│                 (Script en Python)                  │
└───────────────────────┬─────────────────────────────┘
                        │ POST /request-ride
                        ▼
          ┌─────────────────────────┐
          │   Ingestion Service     │  Go
          │   (API Gateway)         │  :8080
          │   Recibe solicitudes y  │
          │   deriva al orquestador │
          └────────────┬────────────┘
                       │ POST /match (Llamada Interna)
                       ▼
          ┌─────────────────────────┐
          │   Matching Service      │  Elixir
          │   (Orquestador)         │  :4000
          │   Lógica de emparejado  │
          │   y gestión de estado   │
          └────────────┬────────────┘
                       │ POST /fare (Llamada Interna)
                       ▼
          ┌─────────────────────────┐
          │   Pricing Service       │  Ruby
          │   (Lógica de Negocio)   │  :3000
          │   Cálculo dinámico      │
          │   (demanda × distancia) │
          └─────────────────────────┘
```

Cada servicio se puede desplegar de forma independiente y se comunica a través de HTTP sobre la red interna de Docker. Esto refleja una versión simplificada del diseño backend real de una aplicación de movilidad, donde la ingesta, la orquestación y la lógica de negocio son responsabilidades separadas.

## Servicios

### 1. Ingestion Service — Go (:8080)
Actúa como la puerta de entrada (API Gateway) del sistema. Recibe las peticiones de los usuarios y las reenvía al servicio correspondiente.
Go es un sistema de baja latencia, modelo de concurrencia sólido y consumo mínimo de memoria, ideal para la capa de ingesta en sistemas con alto volumen de tráfico concurrente.

### 2. Matching Service — Elixir (:4000)
Actúa como el orquestador principal. Recibe la petición, genera un emparejamiento con un conductor disponible (simulado), y consulta los precios antes de devolver la respuesta final al usuario.


### 3. Pricing Service — Ruby (:3000)
Recibe los datos del viaje (distancia, tiempo, multiplicador de demanda) y devuelve una tarifa dinámica calculada al instante.
Ruby tiene una sintaxis altamente expresiva y natural, ideal para traducir reglas de negocio complejas en código fácil de leer y mantener.

## Guía de Inicio

### Requisitos Previos
* [Docker](https://docs.docker.com/get-docker/) y Docker Compose
* [Python 3](https://www.python.org/) (Solo para el simulador)

### Cómo arrancar el proyecto

1.  Clona el repositorio y entra en el directorio:
    ```
    git clone https://github.com/daviddramosss/mobility_logic_lab.git
    cd mobility-logic-lab
    ```

2.  Levanta la infraestructura completa (Go, Elixir y Ruby se conectarán automáticamente):
    ```
    docker-compose up --build
    ```

### Ejecutar la Simulación

Para ver la arquitectura en pleno funcionamiento, abre una nueva pestaña en tu terminal y ejecuta el script de simulación de tráfico (asegúrate de tener instalada la librería `requests` de Python):

```
# Si no tienes requests instalado: pip install requests
# Una vez instalado ejecuta:
    python3 simular_trafico.py
```

Podrás observar en la terminal de Docker cómo los tres microservicios registran en tiempo real el flujo de la petición: `Go (Gateway) -> Elixir (Orquestador) -> Ruby (Pricing) -> Respuesta`.


---
Autor: David Ramos De Lucas.
---
