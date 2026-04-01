# Usamos una imagen oficial de Ruby. 
# La etiqueta "slim" significa que es una versión reducida de Debian, ideal para producción.
FROM ruby:3.2.2-slim

# Instalamos herramientas básicas del sistema (build-essential) necesarias 
# porque algunas gemas (como Puma) compilan pequeñas extensiones en C al instalarse.
RUN apt-get update -qq && apt-get install -y build-essential

# Establecemos nuestra carpeta de trabajo en el contenedor
WORKDIR /app

# Copiamos SOLO el Gemfile primero. 
# Hacemos esto por rendimiento: Docker cachea las capas. Si no cambias las librerías, 
# Docker se saltará este paso en el futuro y la imagen se construirá en segundos.
COPY Gemfile ./

# Instalamos las dependencias (el equivalente a 'pip install -r requirements.txt')
RUN bundle install

# Copiamos el resto de nuestro código (la carpeta app/)
COPY . .

# Documentamos que nuestro servicio escucha en el puerto 3000
EXPOSE 3000

# El comando exacto para arrancar la aplicación
CMD ["ruby", "app/pricing_service.rb"]