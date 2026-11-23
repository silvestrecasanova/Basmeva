class_name Gestor_Habilidades
extends Node
## Registra las habilidades, las actualiza y coordina las incompatibilidades.
## No conoce ninguna habilidad en concreto: trabaja solo con Habilidad_Base.
## Las habilidades se asignan por el Inspector en Scripts_Habilidades.

signal Habilidad_Registrada(nombre: String)
signal Habilidad_Quitada(nombre: String)

## Arrastra aquí los scripts de las habilidades (cada uno debe extender Habilidad_Base).
@export var Scripts_Habilidades: Array[Script] = []

var Dueno: Personaje

## Nombre -> habilidad.
var Registro: Dictionary = {}

## Mismas habilidades en orden de registro (el orden de actualización).
var Lista: Array[Habilidad_Base] = []

## Solo las habilidades desbloqueadas (Habilitada = true). Es la única que se
## recorre cada frame, así que no hace falta comprobar nada por habilidad.
var Lista_Activa: Array[Habilidad_Base] = []

## Habilidad activa que impide actuar a las demás (por ejemplo, el dash).
var Bloqueadora: Habilidad_Base = null

## Registro dinámico de funciones: "habilidad.funcion" -> Callable.
var Funciones: Dictionary = {}


func Inicializar(personaje: Personaje) -> void:
	Dueno = personaje
	for script in Scripts_Habilidades:
		if script != null:
			Agregar_Script(script)


## Crea la habilidad desde su script y la registra. Es la forma de DESBLOQUEAR una
## habilidad durante la partida (por ejemplo, al recoger un objeto). Scripts_Habilidades
## solo necesita las que el jugador tiene al empezar; puede estar vacío.
func Agregar_Script(script: Script) -> Habilidad_Base:
	var clase := script as GDScript
	if clase == null or not clase.can_instantiate():
		push_error("Gestor_Habilidades: el script no se puede instanciar.")
		return null
	var objeto: Variant = clase.new()
	if not (objeto is Habilidad_Base):
		push_error("Gestor_Habilidades: %s no extiende Habilidad_Base." % clase.resource_path)
		if objeto is Node:
			objeto.free()
		return null
	var habilidad: Habilidad_Base = objeto
	if habilidad.Nombre.is_empty() or Registro.has(habilidad.Nombre):
		push_error("Gestor_Habilidades: nombre vacío o repetido en %s." % clase.resource_path)
		habilidad.free()
		return null

	habilidad.name = habilidad.Nombre
	add_child(habilidad)
	Registro[habilidad.Nombre] = habilidad
	Lista.append(habilidad)

	var acciones: Dictionary = habilidad.Acciones_Por_Defecto()
	for accion in acciones:
		Dueno.Acciones.Registrar_Accion(accion, acciones[accion])

	habilidad.Aplicar_Config(Dueno.Config.Obtener_Habilidad(habilidad.Nombre))
	habilidad.Inicializar(Dueno)
	Reconstruir_Lista_Activa()
	Habilidad_Registrada.emit(habilidad.Nombre)
	return habilidad


func Quitar_Habilidad(nombre: String) -> void:
	if not Registro.has(nombre):
		return
	var habilidad: Habilidad_Base = Registro[nombre]
	Solicitar_Fin(habilidad)
	habilidad.Quitar_Funciones()
	Registro.erase(nombre)
	Lista.erase(habilidad)
	Lista_Activa.erase(habilidad)
	Habilidad_Quitada.emit(nombre)
	habilidad.queue_free()


func Actualizar(delta: float) -> void:
	for habilidad in Lista_Activa:
		if Bloqueadora != null and Bloqueadora != habilidad:
			continue
		habilidad.Actualizar(delta)


# ---------------------------------------------------------------------------
# Consulta y estado
# ---------------------------------------------------------------------------

func Tiene(nombre: String) -> bool:
	return Registro.has(nombre)


func Obtener(nombre: String) -> Habilidad_Base:
	return Registro.get(nombre, null)


func Esta_Habilitada(nombre: String) -> bool:
	var habilidad := Obtener(nombre)
	return habilidad != null and habilidad.Habilitada


func Habilitar(nombre: String, valor: bool = true) -> void:
	var habilidad := Obtener(nombre)
	if habilidad == null:
		return
	habilidad.Habilitada = valor
	if not valor:
		Solicitar_Fin(habilidad)
	Reconstruir_Lista_Activa()


## Vuelve a armar Lista_Activa respetando el orden de registro.
func Reconstruir_Lista_Activa() -> void:
	Lista_Activa.assign(Lista.filter(func(habilidad: Habilidad_Base) -> bool: return habilidad.Habilitada))


func Gravedad_Anulada() -> bool:
	for habilidad in Lista_Activa:
		if habilidad.Activa and habilidad.Anula_Gravedad:
			return true
	return false


# ---------------------------------------------------------------------------
# Activación coordinada (evita activaciones incompatibles)
# ---------------------------------------------------------------------------

func Solicitar_Activacion(habilidad: Habilidad_Base) -> bool:
	if habilidad.Activa or not habilidad.Habilitada:
		return false
	if Bloqueadora != null and Bloqueadora != habilidad:
		return false
	habilidad.Activa = true
	if habilidad.Bloquea_Otras:
		Bloqueadora = habilidad
	habilidad.Activar()
	habilidad.Activada.emit()
	return true


func Solicitar_Fin(habilidad: Habilidad_Base) -> void:
	if not habilidad.Activa:
		return
	habilidad.Activa = false
	if Bloqueadora == habilidad:
		Bloqueadora = null
	habilidad.Desactivar()
	habilidad.Desactivada.emit()


# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------

## Cada habilidad aporta su porción del JSON.
func Obtener_Config() -> Dictionary:
	var datos: Dictionary = {}
	for habilidad in Lista:
		datos[habilidad.Nombre] = habilidad.Obtener_Config()
	return datos


# ---------------------------------------------------------------------------
# Registro dinámico de funciones (Callable)
# ---------------------------------------------------------------------------

func Registrar_Funcion(nombre: String, funcion: Callable) -> void:
	Funciones[nombre] = funcion


func Quitar_Funcion(nombre: String) -> void:
	Funciones.erase(nombre)


func Tiene_Funcion(nombre: String) -> bool:
	return Funciones.has(nombre)


func Ejecutar_Funcion(nombre: String, parametros: Array = []) -> Variant:
	if not Funciones.has(nombre):
		push_warning("Gestor_Habilidades: la función '%s' no está registrada." % nombre)
		return null
	var funcion: Callable = Funciones[nombre]
	if not funcion.is_valid():
		Funciones.erase(nombre)
		push_warning("Gestor_Habilidades: la función '%s' ya no es válida." % nombre)
		return null
	return funcion.callv(parametros)
