extends Habilidad_Base
## Salto desde el suelo.

var Fuerza: float = 450.0


func _init() -> void:
	Nombre = "salto"


func Parametros_Por_Defecto() -> Dictionary:
	return {"fuerza": 450.0}


func Acciones_Por_Defecto() -> Dictionary:
	return {"saltar": [KEY_SPACE, KEY_W, KEY_UP]}


func Al_Cambiar_Config() -> void:
	Fuerza = float(Parametros["fuerza"])


func Actualizar(_delta: float) -> void:
	if Dueno.Fisica.En_Suelo and Dueno.Acciones.Recien_Presionada("saltar"):
		Intentar_Activar(true)


func Activar() -> void:
	Dueno.Fisica.Establecer_Velocidad_Y(-Fuerza)
