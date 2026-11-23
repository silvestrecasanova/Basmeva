
@tool
class_name Bloque_Colision
extends StaticBody2D
## Bloque de colisión para armar escenarios por celdas (suelo, techo, pared, plataforma).
## Agrégalo como nodo nuevo (tipo Bloque_Colision) y escribe su tamaño en celdas:
## Ancho_Celdas = 1 y Alto_Celdas = 2 crea un bloque de 1x2 celdas con su colisión
## y su visual ajustados. El nodo marca el centro del bloque.
## Úsalo en un nodo nuevo, no sobre un StaticBody2D que ya tenga su colisión.

enum Tipo_Bloque { SOLIDO, UNIDIRECCIONAL }

@export var Tipo: Tipo_Bloque = Tipo_Bloque.SOLIDO:
	set(valor):
		Tipo = valor
		Actualizar()

@export_range(0.25, 200.0, 0.25, "or_greater") var Ancho_Celdas: float = 1.0:
	set(valor):
		Ancho_Celdas = maxf(valor, 0.25)
		Actualizar()

@export_range(0.25, 200.0, 0.25, "or_greater") var Alto_Celdas: float = 1.0:
	set(valor):
		Alto_Celdas = maxf(valor, 0.25)
		Actualizar()

## Debe coincidir con el Tamano_Celda de la Guia_Rejilla.
@export_range(4.0, 256.0, 1.0, "or_greater") var Tamano_Celda: float = 32.0:
	set(valor):
		Tamano_Celda = maxf(valor, 1.0)
		Actualizar()

@export var Color_Visual: Color = Color(0.22, 0.27, 0.35, 1.0):
	set(valor):
		Color_Visual = valor
		Actualizar()

## En el editor, el bloque se pega a la cuadrícula al moverlo.
@export var Ajustar_A_Rejilla: bool = true


func _init() -> void:
	Actualizar.call_deferred()


func _ready() -> void:
	set_process(Engine.is_editor_hint())
	Actualizar()


func _process(_delta: float) -> void:
	if not Ajustar_A_Rejilla:
		return
	var ajustada: Vector2 = position.snapped(Vector2(Tamano_Celda, Tamano_Celda))
	if ajustada != position:
		position = ajustada


func Actualizar() -> void:
	if not is_node_ready():
		return

	var tamano: Vector2 = Vector2(Ancho_Celdas, Alto_Celdas) * Tamano_Celda
	var mitad: Vector2 = tamano / 2.0
	var unidireccional: bool = Tipo == Tipo_Bloque.UNIDIRECCIONAL

	# CollisionShape2D: misma dimensión y centro.
	var colision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if colision != null:
		var forma := colision.shape as RectangleShape2D
		if forma == null:
			forma = RectangleShape2D.new()
			colision.shape = forma

		forma.size = tamano
		colision.position = Vector2.ZERO
		colision.scale = Vector2.ONE
		colision.one_way_collision = unidireccional

	# Visual: Polygon2D con exactamente las mismas dimensiones.
	var visual := get_node_or_null("Visual") as Polygon2D
	if visual != null:
		visual.polygon = PackedVector2Array([
			Vector2(-mitad.x, -mitad.y),
			Vector2(mitad.x, -mitad.y),
			Vector2(mitad.x, mitad.y),
			Vector2(-mitad.x, mitad.y)
		])
		visual.position = Vector2.ZERO
		visual.scale = Vector2.ONE
		visual.color = Color_Visual

	var grupo_nuevo: String = "unidireccional" if unidireccional else "suelo"
	var grupo_viejo: String = "suelo" if unidireccional else "unidireccional"

	if is_in_group(grupo_viejo):
		remove_from_group(grupo_viejo)
	if not is_in_group(grupo_nuevo):
		add_to_group(grupo_nuevo, true)

	queue_redraw()


func _draw() -> void:
	var tamano: Vector2 = Vector2(Ancho_Celdas, Alto_Celdas) * Tamano_Celda
	var mitad: Vector2 = tamano / 2.0
	draw_rect(Rect2(-mitad, tamano), Color_Visual)
	draw_rect(Rect2(-mitad, tamano), Color_Visual.lightened(0.35), false, 1.0)
