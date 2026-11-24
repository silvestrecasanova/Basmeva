extends Habilidad_Base
## Deslizarse por el suelo con ESQUIVAR (L) + ABAJO. Mientras desliza, el collider
## y el sprite se achican (pegados al suelo) para pasar por debajo de obstáculos.
## - Solo se inicia desde el suelo; no se desliza en el aire.
## - No anula la gravedad: si sale por el borde del suelo o de una plataforma, cae
##   y el deslizamiento termina (salvo que haya techo encima, ver abajo).
## - Al acabar el tiempo, si no cabe de pie (techo encima), sigue agachado avanzando
##   despacio (velocidad_bajo_techo) hasta tener espacio. Con el movimiento se puede
##   cambiar de dirección ahí debajo.
## - Bloquea otras habilidades mientras dura (no se puede saltar ni hacer dash).
## Debe ir DESPUÉS de Caminar en Scripts_Habilidades.
## (El esquivar parado, sin ABAJO, será otra habilidad que use la misma acción.)

## Segundos que se sigue considerando "en el suelo" tras perderlo. Evita que un
## parpadeo de is_on_floor() mientras se camina cancele o impida el deslizamiento.
const Gracia_Suelo: float = 0.1

var Tiempo_Sin_Suelo: float = 0.0

var Velocidad_Deslizar: float = 500.0
var Duracion: float = 0.4
var Recuperacion: float = 0.3
var Altura: float = 32.0
var Velocidad_Bajo_Techo: float = 150.0

var Direccion: float = 1.0
var Tiempo_Restante: float = 0.0
var Tiempo_Recuperacion: float = 0.0

var Colision: CollisionShape2D
var Forma_Original: Shape2D
var Posicion_Original: Vector2
var Forma_Consulta: RectangleShape2D
var Escala_Sprite_Original: Vector2
var Posicion_Sprite_Original: Vector2


func _init() -> void:
	Nombre = "deslizar"
	Bloquea_Otras = true


func Parametros_Por_Defecto() -> Dictionary:
	return {"velocidad": 500.0, "duracion": 0.4, "recuperacion": 0.3, "altura": 32.0, "velocidad_bajo_techo": 150.0}


func Acciones_Por_Defecto() -> Dictionary:
	return {"esquivar": [KEY_L], "abajo": [KEY_S, KEY_DOWN]}


func Al_Cambiar_Config() -> void:
	Velocidad_Deslizar = float(Parametros["velocidad"])
	Duracion = float(Parametros["duracion"])
	Recuperacion = float(Parametros["recuperacion"])
	Altura = float(Parametros["altura"])
	Velocidad_Bajo_Techo = float(Parametros["velocidad_bajo_techo"])


func Inicializar(personaje: Personaje) -> void:
	super(personaje)
	Colision = Dueno.get_node("CollisionShape2D") as CollisionShape2D
	Registrar_Funcion("Esta_Activo", Esta_Activo)
	Registrar_Funcion("Esta_Listo", Esta_Listo)


func Actualizar(delta: float) -> void:
	if Dueno.Fisica.En_Suelo:
		Tiempo_Sin_Suelo = 0.0
	else:
		Tiempo_Sin_Suelo += delta
	if Tiempo_Recuperacion > 0.0:
		Tiempo_Recuperacion -= delta
	if Activa:
		Mantener_Deslizamiento(delta)
		return
	if Esta_Listo() and Sobre_Suelo() \
			and Dueno.Acciones.Presionada("abajo") \
			and Dueno.Acciones.Recien_Presionada("esquivar"):
		Intentar_Activar()


func Mantener_Deslizamiento(delta: float) -> void:
	Tiempo_Restante -= delta
	var hay_techo: bool = Hay_Techo()
	# Sin techo encima: termina al acabarse el tiempo, al salir del suelo o al chocar con una pared.
	if not hay_techo and (Tiempo_Restante <= 0.0 or not Sobre_Suelo() or Dueno.is_on_wall()):
		Terminar()
		return
	var velocidad: float = Velocidad_Deslizar
	if Tiempo_Restante <= 0.0:
		# Agachado bajo un techo: avanza despacio y deja cambiar de dirección.
		velocidad = Velocidad_Bajo_Techo
		var entrada: float = signf(Dueno.Acciones.Direccion_Horizontal)
		if entrada != 0.0:
			Direccion = entrada
	Dueno.Fisica.Establecer_Velocidad_X(Direccion * velocidad)


func Activar() -> void:
	var entrada: float = signf(Dueno.Acciones.Direccion_Horizontal)
	Direccion = entrada if entrada != 0.0 else float(Dueno.Direccion_Mirada)
	Dueno.Direccion_Mirada = 1 if Direccion > 0.0 else -1
	Tiempo_Restante = Duracion
	Achicar()
	Dueno.Fisica.Establecer_Velocidad_X(Direccion * Velocidad_Deslizar)


func Desactivar() -> void:
	Restaurar()
	Dueno.Fisica.Establecer_Velocidad_X(0.0)
	Tiempo_Recuperacion = Recuperacion


## Achica el collider y el sprite dejando los pies en el mismo sitio.
func Achicar() -> void:
	Forma_Original = Colision.shape
	Posicion_Original = Colision.position
	var original := Forma_Original as RectangleShape2D
	var altura: float = clampf(Altura, 2.0, original.size.y)

	var nueva := RectangleShape2D.new()
	nueva.size = Vector2(original.size.x, altura)
	Colision.shape = nueva
	Colision.position = Posicion_Original + Vector2(0.0, (original.size.y - altura) / 2.0)

	# Forma ligeramente más pequeña que la de pie, para detectar techo sin falsos
	# positivos por rozar el suelo o las paredes.
	Forma_Consulta = RectangleShape2D.new()
	Forma_Consulta.size = original.size - Vector2(2.0, 2.0)

	Escala_Sprite_Original = Dueno.Sprite.scale
	Posicion_Sprite_Original = Dueno.Sprite.position
	var factor: float = altura / original.size.y
	Dueno.Sprite.scale = Vector2(Escala_Sprite_Original.x, Escala_Sprite_Original.y * factor)
	Dueno.Sprite.position = Posicion_Sprite_Original + Vector2(0.0, (original.size.y - altura) / 2.0)


func Restaurar() -> void:
	if Forma_Original == null:
		return
	Colision.shape = Forma_Original
	Colision.position = Posicion_Original
	Dueno.Sprite.scale = Escala_Sprite_Original
	Dueno.Sprite.position = Posicion_Sprite_Original
	Forma_Original = null


## Verdadero si el personaje NO cabe de pie en su posición actual.
## Las plataformas unidireccionales no cuentan (se atraviesan por debajo).
func Hay_Techo() -> bool:
	if Forma_Original == null:
		return false
	var consulta := PhysicsShapeQueryParameters2D.new()
	consulta.shape = Forma_Consulta
	consulta.transform = Dueno.global_transform * Transform2D(0.0, Posicion_Original)
	consulta.collision_mask = Dueno.collision_mask
	consulta.exclude = [Dueno.get_rid()]
	var resultados: Array[Dictionary] = Dueno.get_world_2d().direct_space_state.intersect_shape(consulta, 8)
	for resultado in resultados:
		var cuerpo: Object = resultado["collider"]
		if cuerpo is Node and (cuerpo as Node).is_in_group("unidireccional"):
			continue
		return true
	return false


func Sobre_Suelo() -> bool:
	return Tiempo_Sin_Suelo <= Gracia_Suelo


func Esta_Activo() -> bool:
	return Activa


func Esta_Listo() -> bool:
	return not Activa and Tiempo_Recuperacion <= 0.0
