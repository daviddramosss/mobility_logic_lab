package model

// Location representa una coordenada GPS enviada por un conductor o un pasajero.
// Al empezar con mayúscula, la estructura es "Pública" (exportada) para otros paquetes.
type Location struct {
	ID   string  `json:"id"`
	Type string  `json:"type"` // Usaremos "rider" para pasajero y "driver" para conductor
	Lat  float64 `json:"lat"`
	Lng  float64 `json:"lng"`
}

// Response es un modelo genérico para contestar a las peticiones HTTP
type Response struct {
	Status  string `json:"status"`
	Message string `json:"message"`
}
