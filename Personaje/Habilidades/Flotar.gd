extends Habilidad_Base
## Flotar en el aire con el botón de salto MANTENIDO. Si el personaje está cayendo
## y el botón de salto está presionado, desciende despacio a velocidad constante.
## Sirve tras un salto, un doble salto o una caída: basta con mantener el botón.
## Se corta al soltar el botón, al aterrizar, al agotarse el tiempo, al mantener
## "abajo" o si otra habilidad lo impulsa hacia arriba (por ejemplo, un doble salto).
## "duracion" es el tiempo total de flote por cada vez en el aire (se recupera al
## aterrizar). Si vale 0, la flotación es ilimitada.

var Velocidad_Caida: float = 60.0
var Duracion: float = 1.5
var Tiempo_Usado: float = 0.0


func _init() -> void:
	Nombre = "flotar"
	Anula_Gravedad = true


func Parametros_Por_Defecto() -> Dictionary:
	return {"velocidad_caida": 60.0, "duracion": 1.5}


func Acciones_Por_Defecto() -> Dictionary:
	return {"saltar": [KEY_SPACE]}


func Al_Cambiar_Config() -> void:
	Velocidad_Caida = float(Parametros["velocidad_caida"])
	Duracion = float(Parametros["duracion"])


func Inicializar(personaje: Personaje) -> void:
	super(personaje)
	Dueno.Fisica.Aterrizo.connect(Al_Aterrizar)
	Registrar_Funcion("Esta_Activo", Esta_Activo)
	Registrar_Funcion("Tiempo_Restante", Tiempo_Restante)


func Actualizar(delta: float) -> void:
	if Activa:
		Mantener_Flote(delta)
		return
	if Dueno.Fisica.En_Suelo or Tiempo_Restante() <= 0.0:
		return
	# Solo se empieza a flotar cuando el personaje ya está cayendo.
	if Dueno.velocity.y > 0.0 and Dueno.Acciones.Presionada("saltar") and not Abajo_Presionado():
		Intentar_Activar()


func Mantener_Flote(delta: float) -> void:
	# Otra habilidad lo impulsó hacia arriba: cede el control.
	if Dueno.velocity.y < 0.0:
		Terminar()
		return
	Tiempo_Usado += delta
	if not Dueno.Acciones.Presionada("saltar") or Abajo_Presionado() or Tiempo_Restante() <= 0.0:
		Terminar()
		return
	Dueno.Fisica.Establecer_Velocidad_Y(Velocidad_Caida)


func Activar() -> void:
	Dueno.Fisica.Establecer_Velocidad_Y(Velocidad_Caida)


func Al_Aterrizar() -> void:
	Tiempo_Usado = 0.0
	if Activa:
		Terminar()


## "abajo" lo registra Bajar_Plataforma; si esa habilidad no está, la acción puede no existir.
func Abajo_Presionado() -> bool:
	return InputMap.has_action("abajo") and Dueno.Acciones.Presionada("abajo")


func Esta_Activo() -> bool:
	return Activa


## Segundos de flote que quedan. Con duracion = 0 es ilimitado (INF).
func Tiempo_Restante() -> float:
	if Duracion <= 0.0:
		return INF
	return maxf(Duracion - Tiempo_Usado, 0.0)
