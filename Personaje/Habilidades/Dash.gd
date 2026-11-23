extends Habilidad_Base
## Impulso horizontal rápido. Mientras dura anula la gravedad y bloquea
## a las demás habilidades.

var Velocidad_Dash: float = 700.0
var Duracion: float = 0.2
var Recuperacion: float = 0.4

var Direccion: float = 1.0
var Tiempo_Restante: float = 0.0
var Tiempo_Recuperacion: float = 0.0


func _init() -> void:
	Nombre = "dash"
	Anula_Gravedad = true
	Bloquea_Otras = true


func Parametros_Por_Defecto() -> Dictionary:
	return {"velocidad": 700.0, "duracion": 0.2, "recuperacion": 0.4}


func Acciones_Por_Defecto() -> Dictionary:
	return {"dash": [KEY_SHIFT, KEY_K]}


func Al_Cambiar_Config() -> void:
	Velocidad_Dash = float(Parametros["velocidad"])
	Duracion = float(Parametros["duracion"])
	Recuperacion = float(Parametros["recuperacion"])


func Inicializar(personaje: Personaje) -> void:
	super(personaje)
	Registrar_Funcion("Esta_Activo", Esta_Activo)
	Registrar_Funcion("Esta_Listo", Esta_Listo)


func Actualizar(delta: float) -> void:
	if Tiempo_Recuperacion > 0.0:
		Tiempo_Recuperacion -= delta
	if Activa:
		Tiempo_Restante -= delta
		Dueno.Fisica.Establecer_Velocidad(Vector2(Direccion * Velocidad_Dash, 0.0))
		if Tiempo_Restante <= 0.0:
			Terminar()
		return
	if Esta_Listo() and Dueno.Acciones.Recien_Presionada("dash"):
		Intentar_Activar()


func Activar() -> void:
	var entrada: float = signf(Dueno.Acciones.Direccion_Horizontal)
	Direccion = entrada if entrada != 0.0 else float(Dueno.Direccion_Mirada)
	Tiempo_Restante = Duracion
	Dueno.Fisica.Establecer_Velocidad(Vector2(Direccion * Velocidad_Dash, 0.0))


func Desactivar() -> void:
	Dueno.Fisica.Establecer_Velocidad_X(0.0)
	Tiempo_Recuperacion = Recuperacion


func Esta_Activo() -> bool:
	return Activa


func Esta_Listo() -> bool:
	return not Activa and Tiempo_Recuperacion <= 0.0
