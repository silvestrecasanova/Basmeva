class_name Habilidad_Base
extends Node
## Clase base de todas las habilidades.
## Para crear una habilidad nueva: extiende esta clase, define Nombre en _init()
## y sobreescribe solo lo que necesites. No hace falta tocar ningún otro script.

signal Activada
signal Desactivada

## Clave única de la habilidad (se usa en el JSON y en el registro de funciones).
var Nombre: String = ""

## Personaje dueño de la habilidad (se asigna en Inicializar).
var Dueno: Personaje

## Desbloqueada. Si es false, el gestor no la actualiza ni permite activarla.
var Habilitada: bool = true

## Verdadero mientras la acción está en curso (por ejemplo, durante un dash).
var Activa: bool = false

## Mientras esté Activa: anula la gravedad / impide que otras habilidades actúen.
var Anula_Gravedad: bool = false
var Bloquea_Otras: bool = false

## Valores configurables (se leen y se guardan en Config.json).
var Parametros: Dictionary = {}

var Funciones_Registradas: Array[String] = []


# ---------------------------------------------------------------------------
# Interfaz común (el gestor llama a estas funciones)
# ---------------------------------------------------------------------------

func Inicializar(personaje: Personaje) -> void:
	Dueno = personaje


## Se llama cuando la acción comienza.
func Activar() -> void:
	pass


## Se llama cada frame de físicas mientras la habilidad esté habilitada y no bloqueada.
## Aquí la habilidad revisa las entradas y el estado, y decide si actúa.
func Actualizar(_delta: float) -> void:
	pass


## Se llama cuando la acción termina.
func Desactivar() -> void:
	pass


# ---------------------------------------------------------------------------
# Configuración (cada habilidad aporta su propia porción del JSON)
# ---------------------------------------------------------------------------

## Valores por defecto. Usa floats para los números (300.0, no 300).
func Parametros_Por_Defecto() -> Dictionary:
	return {}


## Acciones del Input Map que necesita: { "accion": [KEY_X, KEY_Y] }.
## Se registran solas si no existen en el Input Map del proyecto.
func Acciones_Por_Defecto() -> Dictionary:
	return {}


## Se llama cuando cambian los parámetros: aquí se copian a variables tipadas.
func Al_Cambiar_Config() -> void:
	pass


func Aplicar_Config(datos: Dictionary) -> void:
	Parametros = Parametros_Por_Defecto()
	Habilitada = true
	for clave in datos:
		if clave == "habilitada":
			Habilitada = bool(datos[clave])
		else:
			Parametros[clave] = datos[clave]
	Al_Cambiar_Config()


## Porción de JSON de esta habilidad. Se puede sobreescribir si hace falta algo especial.
func Obtener_Config() -> Dictionary:
	var datos: Dictionary = Parametros.duplicate(true)
	datos["habilitada"] = Habilitada
	return datos


func Establecer_Parametro(clave: String, valor: Variant) -> void:
	Parametros[clave] = valor
	Al_Cambiar_Config()


# ---------------------------------------------------------------------------
# Utilidades para las habilidades hijas
# ---------------------------------------------------------------------------

## Pide al gestor iniciar la acción. Si es instantánea (un salto) termina enseguida.
func Intentar_Activar(instantanea: bool = false) -> bool:
	if not Dueno.Habilidades.Solicitar_Activacion(self):
		return false
	if instantanea:
		Terminar()
	return true


func Terminar() -> void:
	Dueno.Habilidades.Solicitar_Fin(self)


## Registra una función propia (Callable) en el gestor con el nombre "habilidad.funcion".
func Registrar_Funcion(nombre_funcion: String, funcion: Callable) -> void:
	var clave: String = "%s.%s" % [Nombre, nombre_funcion]
	Dueno.Habilidades.Registrar_Funcion(clave, funcion)
	Funciones_Registradas.append(clave)


func Quitar_Funciones() -> void:
	for clave in Funciones_Registradas:
		Dueno.Habilidades.Quitar_Funcion(clave)
	Funciones_Registradas.clear()
