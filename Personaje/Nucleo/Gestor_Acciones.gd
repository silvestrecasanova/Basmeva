class_name Gestor_Acciones
extends Node
## Lee las entradas del jugador a través del Input Map.
## No ordena nada a nadie: expone la intención del jugador y cada habilidad
## consulta lo que le interesa.

const Accion_Izquierda: StringName = &"mover_izquierda"
const Accion_Derecha: StringName = &"mover_derecha"

var Dueno: Personaje

## Permite bloquear todas las entradas (cinemáticas, menús, campos de texto...).
var Entradas_Activas: bool = true

## -1 (izquierda) a 1 (derecha).
var Direccion_Horizontal: float = 0.0


func Inicializar(personaje: Personaje) -> void:
	Dueno = personaje
	Registrar_Accion(Accion_Izquierda, [KEY_A, KEY_LEFT])
	Registrar_Accion(Accion_Derecha, [KEY_D, KEY_RIGHT])


## Crea la acción en el Input Map solo si no existe (respeta lo que definas en el proyecto).
func Registrar_Accion(nombre: StringName, teclas: Array) -> void:
	if InputMap.has_action(nombre):
		return
	InputMap.add_action(nombre)
	for tecla in teclas:
		var evento := InputEventKey.new()
		evento.physical_keycode = tecla as Key
		InputMap.action_add_event(nombre, evento)


func Actualizar(_delta: float) -> void:
	if not Entradas_Activas:
		Direccion_Horizontal = 0.0
		return
	Direccion_Horizontal = Input.get_axis(Accion_Izquierda, Accion_Derecha)
	if Direccion_Horizontal != 0.0:
		Dueno.Direccion_Mirada = 1 if Direccion_Horizontal > 0.0 else -1


func Presionada(accion: StringName) -> bool:
	return Entradas_Activas and Input.is_action_pressed(accion)


func Recien_Presionada(accion: StringName) -> bool:
	return Entradas_Activas and Input.is_action_just_pressed(accion)


func Soltada(accion: StringName) -> bool:
	return Entradas_Activas and Input.is_action_just_released(accion)
