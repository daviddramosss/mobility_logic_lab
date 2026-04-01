# ==========================================
# ETAPA 1: Construcción (Builder)
# ==========================================
# Usamos la imagen oficial de Go basada en Alpine (un Linux hiperligero)
FROM golang:1.21-alpine AS builder

# Establecemos el directorio de trabajo dentro del contenedor
WORKDIR /app

# Copiamos el gestor de dependencias
COPY go.mod ./

# Copiamos todo el código fuente de nuestra carpeta local al contenedor
COPY . .

# Compilamos la aplicación. 
# CGO_ENABLED=0 crea un binario estático que no depende de librerías de C externas.
# GOOS=linux asegura que el ejecutable funcione en entornos Linux.
RUN CGO_ENABLED=0 GOOS=linux go build -o ingestion-app ./cmd/main.go

# ==========================================
# ETAPA 2: Ejecución (Runner)
# ==========================================
# Usamos una imagen de Alpine limpia, SIN el compilador de Go (pesa apenas 5MB)
FROM alpine:latest

WORKDIR /root/

# Copiamos ÚNICAMENTE el archivo binario compilado de la etapa anterior
COPY --from=builder /app/ingestion-app .

# Documentamos que este contenedor expone el puerto 8080
EXPOSE 8080

# El comando que se ejecutará al arrancar el contenedor
CMD ["./ingestion-app"]