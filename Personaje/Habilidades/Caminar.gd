extends Habilidad_Base
## Movimiento horizontal.

var Velocidad: float = 300.0


func _init() -> void:
	Nombre = "caminar"


func Parametros_Por_Defecto() -> Dictionary:
	return {"velocidad": 300.0}


func Al_Cambiar_Config() -> void:
	Velocidad = float(Parametros["velocidad"])


func Actualizar(_delta: float) -> void:
	Dueno.Fisica.Establecer_Velocidad_X(Dueno.Acciones.Direccion_Horizontal * Velocidad)
