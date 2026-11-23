class_name Personaje
extends CharacterBody2D
## Personaje 2D modular. Contiene solo las variables generales y coordina el orden
## de ejecución: acciones -> gravedad -> habilidades -> movimiento.
##
## DÓNDE VA CADA VARIABLE (para que las habilidades futuras accedan a ella):
##  - Generales del personaje (gravedad, energía): aquí, en Parametros / Gravedad / Energia.
##    Una habilidad las lee con Dueno.Gravedad, Dueno.Energia.
##  - Estado compartido (Direccion_Mirada): aquí. Dueno.Direccion_Mirada.
##  - Valores propios de una habilidad (velocidad, fuerza...): en la propia habilidad.
##    Otra habilidad los consulta con Dueno.Habilidades.Obtener("dash").Parametros["velocidad"]
##    o, mejor, con una función registrada: Dueno.Habilidades.Ejecutar_Funcion("dash.Esta_Activo").
##  - Suelo/aire y velocidad: Dueno.Fisica (En_Suelo, Establecer_Velocidad_X/Y).
##  - Entradas: Dueno.Acciones (Direccion_Horizontal, Presionada, Recien_Presionada).

@onready var Sprite: Sprite2D = $Sprite2D
@onready var Acciones: Gestor_Acciones = $Gestores/Gestor_Acciones
@onready var Habilidades: Gestor_Habilidades = $Gestores/Gestor_Habilidades
@onready var Fisica: Gestor_Fisico = $Gestores/Gestor_Fisico

var Config: Gestor_Config

## Valores configurables del personaje (sección "personaje" del JSON).
var Parametros: Dictionary = {}

var Gravedad: float = 1200.0
var Energia: float = 100.0

## 1 = derecha, -1 = izquierda.
var Direccion_Mirada: int = 1


func _ready() -> void:
	add_to_group("personaje")
	Config = Gestor_Config.new()
	Config.Cargar()
	Aplicar_Config(Config.Obtener_Seccion("personaje"))
	Fisica.Inicializar(self)
	Acciones.Inicializar(self)
	Habilidades.Inicializar(self)
	Sincronizar_Config()


func _physics_process(delta: float) -> void:
	Acciones.Actualizar(delta)
	Fisica.Aplicar_Gravedad(delta)
	Habilidades.Actualizar(delta)
	Fisica.Mover()
	Sprite.flip_h = Direccion_Mirada < 0


# ---------------------------------------------------------------------------
# Configuración
# ---------------------------------------------------------------------------

func Parametros_Por_Defecto() -> Dictionary:
	return {"gravedad": 1200.0, "energia": 100.0}


func Aplicar_Config(datos: Dictionary) -> void:
	Parametros = Parametros_Por_Defecto()
	for clave in datos:
		Parametros[clave] = datos[clave]
	Al_Cambiar_Config()


func Al_Cambiar_Config() -> void:
	Gravedad = float(Parametros["gravedad"])
	Energia = float(Parametros["energia"])


func Establecer_Parametro(clave: String, valor: Variant) -> void:
	Parametros[clave] = valor
	Al_Cambiar_Config()


## Reúne la porción de JSON del personaje y la de cada habilidad. Conserva las
## secciones de habilidades que no estén registradas ahora mismo.
func Actualizar_Datos_Config() -> void:
	Config.Establecer_Seccion("personaje", Parametros.duplicate(true))
	var habilidades: Dictionary = Config.Obtener_Seccion("habilidades").duplicate(true)
	habilidades.merge(Habilidades.Obtener_Config(), true)
	Config.Establecer_Seccion("habilidades", habilidades)


## Guarda todo en Config.json. Solo funciona en el editor.
func Guardar_Config() -> bool:
	Actualizar_Datos_Config()
	return Config.Guardar()


## En el editor, si falta algo en el JSON (habilidad nueva, archivo inexistente...),
## lo completa solo con los valores por defecto.
func Sincronizar_Config() -> void:
	var antes: String = Gestor_Config.Serializar(Config.Datos)
	Actualizar_Datos_Config()
	if Gestor_Config.Serializar(Config.Datos) != antes:
		Config.Guardar()
