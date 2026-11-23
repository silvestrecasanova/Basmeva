class_name Gestor_Config
extends RefCounted
## Lee y guarda Config.json.
## - En el editor: lee y guarda directamente en res://.
## - En la build: solo lee (res:// es de solo lectura). Si el archivo no está,
##   cada script usa sus valores por defecto.
## IMPORTANTE: al exportar, añade *.json en Exportar > Recursos > "Filtros para
## exportar archivos que no son recursos".

const Ruta_Archivo: String = "res://Personaje/Config.json"

var Datos: Dictionary = {}


static func En_Editor() -> bool:
	return OS.has_feature("editor")


static func Serializar(datos: Dictionary) -> String:
	return JSON.stringify(datos, "\t", true)


func Cargar() -> bool:
	Datos = {}
	if not FileAccess.file_exists(Ruta_Archivo):
		return false
	var archivo := FileAccess.open(Ruta_Archivo, FileAccess.READ)
	if archivo == null:
		push_warning("Gestor_Config: no se pudo abrir %s." % Ruta_Archivo)
		return false
	var texto: String = archivo.get_as_text()
	archivo.close()
	var resultado: Variant = JSON.parse_string(texto)
	if resultado is Dictionary:
		Datos = resultado
		return true
	push_warning("Gestor_Config: %s no es un JSON válido." % Ruta_Archivo)
	return false

func Guardar() -> bool:
	if not En_Editor():
		return false
	var archivo := FileAccess.open(Ruta_Archivo, FileAccess.WRITE)
	if archivo == null:
		push_error("Gestor_Config: no se pudo escribir %s (error %d)." % [Ruta_Archivo, FileAccess.get_open_error()])
		return false
	archivo.store_string(Serializar(Datos))
	archivo.close()
	return true


func Obtener_Seccion(nombre: String) -> Dictionary:
	var seccion: Variant = Datos.get(nombre, {})
	if seccion is Dictionary:
		return seccion
	return {}


func Establecer_Seccion(nombre: String, seccion: Dictionary) -> void:
	Datos[nombre] = seccion


func Obtener_Habilidad(nombre: String) -> Dictionary:
	var seccion: Variant = Obtener_Seccion("habilidades").get(nombre, {})
	if seccion is Dictionary:
		return seccion
	return {}
