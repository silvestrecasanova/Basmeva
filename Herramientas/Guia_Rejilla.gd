@tool
class_name Guia_Rejilla
extends Node2D
## Cuadrícula de referencia visual. Se ve en el editor sin ejecutar el juego y
## no interviene en colisiones ni en el movimiento.
## Medidas de referencia: el personaje mide 1x2 celdas; usa Tamano_Celda para
## comparar saltos y distancias en "N celdas".

@export var Activa: bool = true:
	set(valor):
		Activa = valor
		queue_redraw()

## Tamaño de una celda en píxeles.
@export_range(4.0, 256.0, 1.0, "or_greater") var Tamano_Celda: float = 32.0:
	set(valor):
		Tamano_Celda = maxf(valor, 1.0)
		queue_redraw()

@export_range(1, 500, 1, "or_greater") var Columnas: int = 36:
	set(valor):
		Columnas = maxi(valor, 1)
		queue_redraw()

@export_range(1, 500, 1, "or_greater") var Filas: int = 21:
	set(valor):
		Filas = maxi(valor, 1)
		queue_redraw()

@export var Color_Linea: Color = Color(0.2, 0.9, 0.3, 0.6):
	set(valor):
		Color_Linea = valor
		queue_redraw()

@export_range(0.5, 10.0, 0.5, "or_greater") var Grosor_Linea: float = 1.0:
	set(valor):
		Grosor_Linea = valor
		queue_redraw()

@export var Mostrar_Fondo: bool = true:
	set(valor):
		Mostrar_Fondo = valor
		queue_redraw()

@export var Color_Fondo: Color = Color(0.06, 0.07, 0.09, 1.0):
	set(valor):
		Color_Fondo = valor
		queue_redraw()


func _draw() -> void:
	var ancho: float = Columnas * Tamano_Celda
	var alto: float = Filas * Tamano_Celda
	if Mostrar_Fondo:
		draw_rect(Rect2(0.0, 0.0, ancho, alto), Color_Fondo)
	if not Activa:
		return
	for columna in range(Columnas + 1):
		var x: float = columna * Tamano_Celda
		draw_line(Vector2(x, 0.0), Vector2(x, alto), Color_Linea, Grosor_Linea)
	for fila in range(Filas + 1):
		var y: float = fila * Tamano_Celda
		draw_line(Vector2(0.0, y), Vector2(ancho, y), Color_Linea, Grosor_Linea)
