class_name Rastro_Puntos
extends Node2D
## Herramienta de pruebas: dibuja con puntos el recorrido del personaje.
## Ponla como hijo de cualquier nodo (por ejemplo, de la escena de pruebas o del
## propio Personaje) con este script. Los puntos se dibujan en coordenadas del
## mundo, así que no se mueven con el personaje.
## Todo se puede cambiar en el Inspector, también en vivo (pestaña "Remoto").

## Personaje a seguir. Si se deja vacío, busca el del grupo "personaje".
@export var Objetivo: Personaje

## Desplazamiento de todo el rastro respecto al recorrido del personaje (px).
## Por ejemplo (0, 32) lo deja a la altura de los pies.
@export var Offset: Vector2 = Vector2.ZERO

## Distancia entre un punto y el siguiente, medida a lo largo del recorrido (px).
@export_range(2.0, 200.0, 0.5, "suffix:px") var Distancia_Puntos: float = 12.0

@export_range(1.0, 20.0, 0.5, "suffix:px") var Radio_Punto: float = 3.0
@export var Color_Punto: Color = Color(1.0, 0.85, 0.2, 1.0)

## Cuántos puntos se conservan; los más viejos se borran primero.
@export_range(2, 2000, 1) var Maximo_Puntos: int = 120

## Los puntos más viejos se ven más transparentes.
@export var Desvanecer: bool = true

@export var Z_Indice: int = 100

## Solo existe al ejecutar desde el editor (herramienta de pruebas, como el panel de depuración).
@export var Solo_En_Editor: bool = true

## Puntos guardados SIN el Offset (el Offset se aplica al dibujar).
var Puntos: PackedVector2Array = PackedVector2Array()
var Ultimo_Punto: Vector2 = Vector2.ZERO


func _ready() -> void:
	if Solo_En_Editor and not OS.has_feature("editor"):
		queue_free()
		return
	# Independiente de la posición del padre: dibuja directamente en el mundo.
	top_level = true
	global_transform = Transform2D.IDENTITY
	z_as_relative = false
	z_index = Z_Indice
	# Se actualiza después del personaje para leer su posición ya movida.
	process_priority = 1


func _physics_process(_delta: float) -> void:
	if Objetivo == null:
		Objetivo = get_tree().get_first_node_in_group("personaje") as Personaje
		if Objetivo == null:
			return
	Registrar(Objetivo.global_position)
	queue_redraw()


## Agrega puntos a intervalos regulares (Distancia_Puntos) a lo largo del recorrido,
## aunque el personaje se mueva muy rápido (por ejemplo, en un dash).
func Registrar(posicion: Vector2) -> void:
	if Puntos.is_empty():
		Puntos.append(posicion)
		Ultimo_Punto = posicion
		return
	var distancia: float = Ultimo_Punto.distance_to(posicion)
	# Teletransporte o reaparición: empieza un rastro nuevo en vez de rellenar el salto.
	if distancia > Distancia_Puntos * float(Maximo_Puntos):
		Limpiar()
		Puntos.append(posicion)
		Ultimo_Punto = posicion
		return
	while distancia >= Distancia_Puntos:
		Ultimo_Punto = Ultimo_Punto.move_toward(posicion, Distancia_Puntos)
		Puntos.append(Ultimo_Punto)
		distancia = Ultimo_Punto.distance_to(posicion)
	while Puntos.size() > Maximo_Puntos:
		Puntos.remove_at(0)


func Limpiar() -> void:
	Puntos.clear()
	queue_redraw()


func _draw() -> void:
	var total: int = Puntos.size()
	for i in total:
		var color: Color = Color_Punto
		if Desvanecer:
			color.a *= float(i + 1) / float(total)
		draw_circle(Puntos[i] + Offset, Radio_Punto, color)
