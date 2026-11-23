class_name Gestor_Fisico
extends Node
## Dueño del movimiento: aplica la gravedad, recibe los cambios de velocidad que
## piden las habilidades y ejecuta move_and_slide() una sola vez por frame.

signal Aterrizo
signal Salio_Del_Suelo

var Dueno: Personaje
var En_Suelo: bool = false
var Estaba_En_Suelo: bool = false


func Inicializar(personaje: Personaje) -> void:
	Dueno = personaje


func Aplicar_Gravedad(delta: float) -> void:
	if Dueno.Habilidades.Gravedad_Anulada():
		return
	if not Dueno.is_on_floor():
		Dueno.velocity.y += Dueno.Gravedad * delta


func Establecer_Velocidad(nueva: Vector2) -> void:
	Dueno.velocity = nueva


func Establecer_Velocidad_X(valor: float) -> void:
	Dueno.velocity.x = valor


func Establecer_Velocidad_Y(valor: float) -> void:
	Dueno.velocity.y = valor


func Mover() -> void:
	Estaba_En_Suelo = En_Suelo
	Dueno.move_and_slide()
	En_Suelo = Dueno.is_on_floor()
	if En_Suelo and not Estaba_En_Suelo:
		Aterrizo.emit()
	elif not En_Suelo and Estaba_En_Suelo:
		Salio_Del_Suelo.emit()
