extends Habilidad_Base
## Saltos en el aire. "cantidad" es el total de saltos permitidos antes de tocar
## el suelo (2 = salto normal + un salto en el aire). Despegar del suelo, saltando
## o cayendo, cuenta como el primer salto.

var Cantidad: int = 2
var Fuerza: float = 450.0
var Saltos_Realizados: int = 0


func _init() -> void:
	Nombre = "doble_salto"


func Parametros_Por_Defecto() -> Dictionary:
	return {"cantidad": 2.0, "fuerza": 450.0}


func Acciones_Por_Defecto() -> Dictionary:
	return {"saltar": [KEY_SPACE, KEY_W, KEY_UP]}


func Al_Cambiar_Config() -> void:
	Cantidad = int(Parametros["cantidad"])
	Fuerza = float(Parametros["fuerza"])


func Inicializar(personaje: Personaje) -> void:
	super(personaje)
	Dueno.Fisica.Aterrizo.connect(Reiniciar_Saltos)
	Dueno.Fisica.Salio_Del_Suelo.connect(Al_Salir_Del_Suelo)
	Registrar_Funcion("Saltos_Restantes", Saltos_Restantes)


func Actualizar(_delta: float) -> void:
	if Dueno.Fisica.En_Suelo or Saltos_Realizados >= Cantidad:
		return
	if Dueno.Acciones.Recien_Presionada("saltar"):
		Intentar_Activar(true)


func Activar() -> void:
	Saltos_Realizados += 1
	Dueno.Fisica.Establecer_Velocidad_Y(-Fuerza)


func Reiniciar_Saltos() -> void:
	Saltos_Realizados = 0


func Al_Salir_Del_Suelo() -> void:
	if Saltos_Realizados == 0:
		Saltos_Realizados = 1


func Saltos_Restantes() -> int:
	return maxi(Cantidad - Saltos_Realizados, 0)
