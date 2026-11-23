extends Habilidad_Base
## Atravesar plataformas unidireccionales hacia abajo: mantener abajo (flecha / S) y pulsar saltar.
## Debe registrarse DESPUÉS de Salto en Scripts_Habilidades.

var Tiempo_Caida: float = 0.25
var Plataforma: Node = null
var Tiempo_Restante: float = 0.0


func _init() -> void:
	Nombre = "bajar_plataforma"


func Parametros_Por_Defecto() -> Dictionary:
	return {"tiempo_caida": 0.25}


func Acciones_Por_Defecto() -> Dictionary:
	return {"abajo": [KEY_S, KEY_DOWN], "saltar": [KEY_SPACE, KEY_W, KEY_UP]}


func Al_Cambiar_Config() -> void:
	Tiempo_Caida = float(Parametros["tiempo_caida"])


func Actualizar(delta: float) -> void:
	if Plataforma != null:
		Tiempo_Restante -= delta
		if Tiempo_Restante <= 0.0:
			if is_instance_valid(Plataforma):
				Dueno.remove_collision_exception_with(Plataforma)
			Plataforma = null
		return
	if Dueno.Fisica.En_Suelo and Dueno.Acciones.Presionada("abajo") and Dueno.Acciones.Recien_Presionada("saltar"):
		for i in Dueno.get_slide_collision_count():
			var cuerpo: Object = Dueno.get_slide_collision(i).get_collider()
			if cuerpo is Node and cuerpo.is_in_group("unidireccional"):
				Plataforma = cuerpo
				Tiempo_Restante = Tiempo_Caida
				Dueno.add_collision_exception_with(cuerpo)
				Dueno.Fisica.Establecer_Velocidad_Y(50.0)
				break
