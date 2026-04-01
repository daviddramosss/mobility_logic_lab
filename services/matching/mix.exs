# "defmodule" define un Módulo. En Elixir no hay Clases, solo Módulos.
# Un Módulo es simplemente una "caja" donde se agrupan funciones relacionadas.
defmodule Matching.MixProject do
  use Mix.Project # Esto inyecta las funciones básicas que necesita Mix para funcionar.

  # La función "project" define los metadatos de tu aplicación.
  def project do
    [
      app: :matching,             # El nombre de tu app. Fíjate en los dos puntos (:). Es un "Átomo".
      version: "0.1.0",           # Versión inicial.
      elixir: "~> 1.14",          # Versión de Elixir que vamos a usar en el Docker.
      start_permanent: true,
      deps: deps()                # Llama a la función "deps" de abajo para cargar librerías.
    ]
  end

  # "application" le dice a la máquina virtual (BEAM) cómo debe arrancar tu código.
  def application do
    [
      extra_applications: [:logger],
      # Aquí le decimos: "Cuando arranques, busca un módulo llamado Matching.Application e inícialo"
      mod: {Matching.Application, []}
    ]
  end

  # "deps" (dependencias) es donde listamos las librerías de terceros.
  # La "p" en "defp" significa que es una función PRIVADA (solo se puede usar dentro de este módulo).
  defp deps do
    [
      # plug_cowboy: Es nuestro servidor web (el equivalente a Sinatra en Ruby o net/http en Go)
      {:plug_cowboy, "~> 2.6"},

      # jason: Es la librería estándar en Elixir para convertir JSON a datos y viceversa
      {:jason, "~> 1.4"},

      # httpoison: Un cliente HTTP. Lo usaremos para llamar a tu servicio de Ruby desde aquí.
      {:httpoison, "~> 2.1"}
    ]
  end
end
