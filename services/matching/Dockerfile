# Cambiamos "alpine" por "slim" (basado en Debian)
FROM elixir:1.14-slim

# En Debian usamos apt-get en lugar de apk para instalar el build-essential
RUN apt-get update && apt-get install -y build-essential

# Preparamos Mix
RUN mix local.hex --force && \
    mix local.rebar --force

# Establecemos el directorio de trabajo
WORKDIR /app

# Copiamos las dependencias
COPY mix.exs ./
RUN mix deps.get

# Copiamos el resto del código y compilamos
COPY . .
RUN mix compile

# Exponemos el puerto
EXPOSE 4000

# Arrancamos la aplicación
CMD ["mix", "run", "--no-halt"]