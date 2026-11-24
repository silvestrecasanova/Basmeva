extends Habilidad_Base
## Agarrarse a la pared, deslizar y saltar de pared en pared.
##
## Hay dos tipos de pared:
##  - Pared normal: no hace nada.
##  - Pared deslizable: la que está en el grupo "pared_deslizable" (igual que "suelo" o
##    "unidireccional": ponle el grupo al StaticBody2D / TileMap de esa pared).
##
## AGARRAR / DESLIZAR: en el aire (subiendo o cayendo), al tocar una pared deslizable el
## personaje se AGARRA: queda quieto "tiempo_agarre" segundos y después desliza, con la
## caída limitada a "velocidad_deslizamiento". Con tiempo_agarre = 0 desliza de inmediato.
## Se corta al tocar el suelo, al perder la pared o al soltar (ver requiere_direccion).
##
## SALTAR: con el botón de salto estando pegado impulsa hacia arriba y en sentido
## contrario a la pared. Durante "bloqueo" segundos se ignora el control horizontal para
## que el impulso cruce en línea recta; si en pleno vuelo toca otra pared deslizable, el
## bloqueo termina enseguida para poder agarrarse. La distancia que recorre hacia el lado
## es aproximadamente fuerza_x * bloqueo (ponlo cercano a la separación de las paredes).
##
## TIEMPO DE REACCIÓN ("tiempo_reaccion"): al dejar de presionar hacia la pared no se
## cae de inmediato; durante ese margen sigue agarrado y el botón de salto todavía
## funciona, aunque ya estés presionando el lado contrario (sale hacia ese lado).
##
## PARÁMETROS DE COMPORTAMIENTO (1 = sí, 0 = no):
##  - requiere_direccion (1): hay que presionar hacia la pared para agarrarse y para
##    saltar de ella, y se suelta al dejar de presionar. Con 0 basta con TOCAR la pared en el aire (sin flechas);
##    se suelta presionando en sentido contrario, al saltar o al tocar el suelo.
##  - recargar_doble_salto (1): agarrarse o saltar de la pared devuelve el doble salto
##    (despegar de la pared cuenta como el primer salto, igual que despegar del suelo).
##  - escalar_misma_pared (0): con 0, si saltas desde una pared y vuelves a la MISMA,
##    solo te agarras (o saltas) si estás a la altura de donde saliste o más abajo; así
##    no se puede escalar una sola pared. Además, al terminar el impulso del salto de
##    pared (bloqueo) la velocidad vertical queda en 0: no sigue subiendo, solo cae.
##    Con 1 se permite escalar y no se recorta la subida. La regla de altura se reinicia
##    al saltar a la pared del otro lado, al tocar el suelo y al usar el doble salto o
##    el dash: tras eso se puede volver a la misma pared a cualquier altura. Un doble salto en el aire también
##    la reinicia: la altura donde lo haces pasa a ser el nuevo límite. Con 0, además, al terminar el impulso
##    del salto de pared (si no tocó otra pared) la velocidad vertical que quede de
##    subida se pone en 0 y el personaje cae.
##
## Debe ir ANTES de Doble_Salto en Scripts_Habilidades (para que el salto de pared
## tenga prioridad sobre el salto en el aire).

enum Fase { NINGUNA, DESLIZANDO, SALTANDO }

const Grupo_Pared: StringName = &"pared_deslizable"
## Segundos tras el salto de pared en los que no se busca pared (evita reagarrar la misma).
const Gracia_Despegue: float = 0.05
## Distancia (px) a la que se busca pared a cada lado del personaje.
const Distancia_Contacto: float = 3.0
## Tolerancia (px) de la regla de escalar la misma pared.
const Margen_Altura: float = 4.0
## Habilidades que, al usarse, reinician la regla de altura de la misma pared.
const Habilidades_Que_Reinician: Array[String] = ["doble_salto", "dash"]

var Velocidad_Deslizamiento: float = 80.0
var Tiempo_Agarre: float = 0.25
var Fuerza_X: float = 350.0
var Fuerza_Y: float = 450.0
var Bloqueo: float = 0.3
var Tiempo_Reaccion: float = 0.15
var Requiere_Direccion: bool = true
var Recargar_Saltos: bool = true
var Escalar_Misma_Pared: bool = false

var Estado: Fase = Fase.NINGUNA
var Normal_Pared: Vector2 = Vector2.ZERO
var Pared_Actual: Node = null
var Tiempo_Sin_Pared: float = 999.0
## Tiempo desde la última vez que se mantuvo la dirección de agarre (ver Mantiene_Agarre).
var Tiempo_Sin_Presionar: float = 999.0
var Tiempo_Agarre_Restante: float = 0.0
var Tiempo_Bloqueo_Restante: float = 0.0
var Impulso_Pendiente: Vector2 = Vector2.ZERO

## Última pared de la que se saltó (para la regla de escalar la misma pared).
var Pared_Salto: Node = null
var Lado_Salto: float = 0.0
var Altura_Salto: float = 0.0

## Saltos de Doble_Salto contados al final del frame anterior (-1 = desconocido).
var Saltos_Anteriores: int = -1
var Doble_Conectado: bool = false

var Choque_Prueba: KinematicCollision2D = KinematicCollision2D.new()


func _init() -> void:
	Nombre = "pared"


func Parametros_Por_Defecto() -> Dictionary:
	return {
		"velocidad_deslizamiento": 80.0,
		"tiempo_agarre": 0.25,
		"fuerza_x": 350.0,
		"fuerza_y": 450.0,
		"bloqueo": 0.3,
		"tiempo_reaccion": 0.15,
		"requiere_direccion": 1.0,
		"recargar_doble_salto": 1.0,
		"escalar_misma_pared": 0.0,
	}


func Acciones_Por_Defecto() -> Dictionary:
	return {"saltar": [KEY_SPACE]}


func Al_Cambiar_Config() -> void:
	Velocidad_Deslizamiento = float(Parametros["velocidad_deslizamiento"])
	Tiempo_Agarre = float(Parametros["tiempo_agarre"])
	Fuerza_X = float(Parametros["fuerza_x"])
	Fuerza_Y = float(Parametros["fuerza_y"])
	Bloqueo = float(Parametros["bloqueo"])
	Tiempo_Reaccion = float(Parametros["tiempo_reaccion"])
	Requiere_Direccion = float(Parametros["requiere_direccion"]) > 0.5
	Recargar_Saltos = float(Parametros["recargar_doble_salto"]) > 0.5
	Escalar_Misma_Pared = float(Parametros["escalar_misma_pared"]) > 0.5


func Inicializar(personaje: Personaje) -> void:
	super(personaje)
	# Usar el doble salto o el dash reinicia la regla de altura de la misma pared.
	for nombre in Dueno.Habilidades.Registro:
		Conectar_Reinicio(nombre)
	Dueno.Habilidades.Habilidad_Registrada.connect(Conectar_Reinicio)
	Registrar_Funcion("Esta_Deslizando", Esta_Deslizando)
	Registrar_Funcion("Esta_Agarrado", Esta_Agarrado)
	Registrar_Funcion("Esta_En_Pared", Esta_En_Pared)


## Se engancha a las habilidades que reinician la regla, estén registradas antes o después.
func Conectar_Reinicio(nombre: String) -> void:
	if not Habilidades_Que_Reinician.has(nombre):
		return
	var otra: Habilidad_Base = Dueno.Habilidades.Obtener(nombre)
	if otra != null and not otra.Activada.is_connected(Reiniciar_Altura):
		otra.Activada.connect(Reiniciar_Altura)


## Olvida la pared de la que se saltó: desde aquí se puede volver a ella a cualquier altura.
func Reiniciar_Altura() -> void:
	Pared_Salto = null


func Actualizar(delta: float) -> void:
	Procesar(delta)
	# Se anota al final de cada frame para poder deshacer un salto gastado por error.
	Saltos_Anteriores = Leer_Saltos()


func Procesar(delta: float) -> void:
	Conectar_Doble_Salto()
	Actualizar_Contacto(delta)
	if Mantiene_Agarre():
		Tiempo_Sin_Presionar = 0.0
	else:
		Tiempo_Sin_Presionar += delta
	if Activa and Estado == Fase.SALTANDO:
		Mantener_Salto(delta)
		return
	if Dueno.Fisica.En_Suelo:
		Pared_Salto = null
		if Activa:
			Terminar()
		return
	if Dueno.Acciones.Recien_Presionada("saltar") and Puede_Saltar_De_Pared():
		Saltar_De_Pared()
		return
	if Activa:
		Mantener_Deslizamiento(delta)
	elif Puede_Agarrarse():
		Estado = Fase.DESLIZANDO
		Intentar_Activar()


# ---------------------------------------------------------------------------
# Detección de pared
# ---------------------------------------------------------------------------

## Busca una pared deslizable pegada a cada lado del personaje, sin depender de que
## se esté empujando contra ella (por eso funciona también sin presionar flechas).
func Actualizar_Contacto(delta: float) -> void:
	var mirada: float = float(Dueno.Direccion_Mirada)
	for lado in [mirada, -mirada]:
		var movimiento := Vector2(float(lado) * Distancia_Contacto, 0.0)
		if not Dueno.test_move(Dueno.global_transform, movimiento, Choque_Prueba):
			continue
		var normal: Vector2 = Choque_Prueba.get_normal()
		var cuerpo := Choque_Prueba.get_collider() as Node
		if absf(normal.x) >= 0.7 and cuerpo != null and cuerpo.is_in_group(Grupo_Pared):
			Normal_Pared = normal
			Pared_Actual = cuerpo
			Tiempo_Sin_Pared = 0.0
			return
	Tiempo_Sin_Pared += delta


## Verdadero si el jugador presiona la dirección que apunta hacia la pared.
func Presionando_Hacia_Pared() -> bool:
	var entrada: float = signf(Dueno.Acciones.Direccion_Horizontal)
	return entrada != 0.0 and entrada == -signf(Normal_Pared.x)


## Verdadero si el jugador presiona la dirección contraria a la pared.
func Presionando_Alejandose() -> bool:
	var entrada: float = signf(Dueno.Acciones.Direccion_Horizontal)
	return entrada != 0.0 and entrada == signf(Normal_Pared.x)


## Verdadero si el jugador está haciendo lo que mantiene el agarre: presionar hacia la
## pared (requiere_direccion = 1) o simplemente no alejarse de ella (requiere_direccion = 0).
func Mantiene_Agarre() -> bool:
	if Requiere_Direccion:
		return Presionando_Hacia_Pared()
	return not Presionando_Alejandose()


## Saltar de la pared: hay que estar pegado a ella (o haberla perdido hace menos de
## tiempo_reaccion) y, si requiere_direccion es 1, haber presionado hacia la pared hace
## menos de tiempo_reaccion. Por eso se puede soltar la flecha, o incluso presionar el
## lado contrario, y saltar justo después: el salto sale igual, alejándose de la pared.
func Puede_Saltar_De_Pared() -> bool:
	if Tiempo_Sin_Pared > Tiempo_Reaccion or not Permite_Esta_Pared():
		return false
	return not Requiere_Direccion or Tiempo_Sin_Presionar <= Tiempo_Reaccion


func Puede_Agarrarse() -> bool:
	if Tiempo_Sin_Pared > 0.0 or not Permite_Esta_Pared():
		return false
	return Mantiene_Agarre()


## Regla de escalar la misma pared: false si es la pared de la que se saltó y el
## personaje está más arriba que donde saltó.
func Permite_Esta_Pared() -> bool:
	if Escalar_Misma_Pared or not is_instance_valid(Pared_Salto):
		return true
	if Pared_Actual != Pared_Salto or signf(Normal_Pared.x) != Lado_Salto:
		return true
	return Dueno.global_position.y >= Altura_Salto - Margen_Altura


# ---------------------------------------------------------------------------
# Agarre y deslizamiento
# ---------------------------------------------------------------------------

func Mantener_Deslizamiento(delta: float) -> void:
	# Al dejar de mantener el agarre hay tiempo_reaccion segundos antes de soltarse;
	# en ese margen todavía se puede saltar de la pared.
	if Tiempo_Sin_Presionar > Tiempo_Reaccion or Tiempo_Sin_Pared > Tiempo_Reaccion:
		Terminar()
		return
	Tiempo_Agarre_Restante = maxf(Tiempo_Agarre_Restante - delta, 0.0)
	Aplicar_Agarre()


## Mientras dura el agarre queda quieto (anula también el impulso que traía);
## después cae como máximo a velocidad_deslizamiento.
func Aplicar_Agarre() -> void:
	if Tiempo_Agarre_Restante > 0.0:
		Dueno.Fisica.Establecer_Velocidad_Y(0.0)
	else:
		Dueno.Fisica.Establecer_Velocidad_Y(clampf(Dueno.velocity.y, 0.0, Velocidad_Deslizamiento))


# ---------------------------------------------------------------------------
# Salto de pared
# ---------------------------------------------------------------------------

func Saltar_De_Pared() -> void:
	var lado: float = signf(Normal_Pared.x)
	var pared: Node = Pared_Actual
	var altura: float = Dueno.global_position.y
	if Activa:
		Terminar()
	Estado = Fase.SALTANDO
	Tiempo_Bloqueo_Restante = Bloqueo
	Impulso_Pendiente = Vector2(lado * Fuerza_X, -Fuerza_Y)
	Dueno.Direccion_Mirada = int(lado)
	# Bloquea a las demás (Caminar, Doble_Salto...) solo durante el impulso.
	Bloquea_Otras = true
	if not Intentar_Activar():
		Bloquea_Otras = false
		Estado = Fase.NINGUNA
		return
	Pared_Salto = pared
	Lado_Salto = lado
	Altura_Salto = altura
	# Ya no se puede volver a saltar desde esta misma pared hasta tocarla de nuevo.
	Tiempo_Sin_Pared = 999.0
	Deshacer_Salto_Del_Frame()
	Recargar_Doble_Salto()


func Mantener_Salto(delta: float) -> void:
	Tiempo_Bloqueo_Restante -= delta
	# Si en pleno vuelo toca otra pared deslizable, termina el impulso para poder agarrarse.
	var toco_pared: bool = Bloqueo - Tiempo_Bloqueo_Restante > Gracia_Despegue and Tiempo_Sin_Pared <= 0.0
	# Con escalar_misma_pared = 0, al acabarse el impulso sin haber llegado a otra pared
	# se corta lo que quede de subida (velocidad vertical a 0): el salto es una diagonal
	# que termina en un punto fijo y desde ahí cae, sin arco que lo devuelva a la misma
	# pared. Así el impulso puede ser fuerte para subir entre dos paredes sin que sirva
	# para escalar una sola.
	if Tiempo_Bloqueo_Restante <= 0.0 and not toco_pared and not Escalar_Misma_Pared and not Dueno.Fisica.En_Suelo:
		Dueno.Fisica.Establecer_Velocidad_Y(maxf(Dueno.velocity.y, 0.0))
	if Tiempo_Bloqueo_Restante <= 0.0 or Dueno.Fisica.En_Suelo or toco_pared:
		# Con escalar_misma_pared = 0, al recuperar el control ya no sigue subiendo:
		# la velocidad vertical queda en 0 y de ahí solo cae.
		if not Escalar_Misma_Pared and Dueno.velocity.y < 0.0:
			Dueno.Fisica.Establecer_Velocidad_Y(0.0)
		Terminar()


func Activar() -> void:
	if Estado == Fase.SALTANDO:
		Dueno.Fisica.Establecer_Velocidad(Impulso_Pendiente)
		return
	# Agarre: si es otra pared distinta a la de la que se saltó, se reinicia la regla.
	if Pared_Actual != Pared_Salto or signf(Normal_Pared.x) != Lado_Salto:
		Pared_Salto = null
	Tiempo_Agarre_Restante = Tiempo_Agarre
	Aplicar_Agarre()
	Recargar_Doble_Salto()


func Desactivar() -> void:
	Bloquea_Otras = false
	Estado = Fase.NINGUNA


## Escucha el doble salto (en cuanto exista, sin importar el orden en que se registre).
func Conectar_Doble_Salto() -> void:
	if Doble_Conectado:
		return
	var doble: Habilidad_Base = Referencia_Doble_Salto()
	if doble == null:
		return
	doble.Activada.connect(Al_Doble_Salto)
	Doble_Conectado = true


## Un doble salto hecho en el aire es un nuevo punto de salida: la altura máxima a la que
## se puede agarrar la misma pared (escalar_misma_pared = 0) pasa a ser donde se hizo.
func Al_Doble_Salto() -> void:
	if is_instance_valid(Pared_Salto):
		Altura_Salto = Dueno.global_position.y


## Habilidad de doble salto, o null si el personaje no la tiene.
func Referencia_Doble_Salto() -> Habilidad_Base:
	var doble: Habilidad_Base = Dueno.Habilidades.Obtener("doble_salto")
	if doble == null or not ("Saltos_Realizados" in doble):
		return null
	return doble


func Leer_Saltos() -> int:
	var doble: Habilidad_Base = Referencia_Doble_Salto()
	return -1 if doble == null else int(doble.get("Saltos_Realizados"))


## Saltar de la pared no gasta el doble salto. Si Doble_Salto está registrado ANTES que
## esta habilidad, ya habrá gastado un salto con esta misma pulsación: aquí se devuelve.
func Deshacer_Salto_Del_Frame() -> void:
	var doble: Habilidad_Base = Referencia_Doble_Salto()
	if doble == null or Saltos_Anteriores < 0:
		return
	# Si esta habilidad corre primero (orden recomendado), Doble_Salto queda bloqueado
	# y no hay nada que deshacer.
	var lista: Array[Habilidad_Base] = Dueno.Habilidades.Lista
	if lista.find(self) < lista.find(doble):
		return
	# En el aire siempre hay al menos 1 contado (el despegue).
	var objetivo: int = maxi(Saltos_Anteriores, 1)
	if int(doble.get("Saltos_Realizados")) > objetivo:
		doble.set("Saltos_Realizados", objetivo)


## Devuelve el doble salto: como mucho queda gastado el "primer salto" (el despegue).
func Recargar_Doble_Salto() -> void:
	if not Recargar_Saltos:
		return
	var doble: Habilidad_Base = Referencia_Doble_Salto()
	if doble == null:
		return
	if int(doble.get("Saltos_Realizados")) > 1:
		doble.set("Saltos_Realizados", 1)


# ---------------------------------------------------------------------------
# Consultas (para animaciones u otras habilidades)
# ---------------------------------------------------------------------------

func Esta_Deslizando() -> bool:
	return Activa and Estado == Fase.DESLIZANDO


## Verdadero mientras está quieto en la pared, antes de empezar a deslizar.
func Esta_Agarrado() -> bool:
	return Esta_Deslizando() and Tiempo_Agarre_Restante > 0.0


func Esta_En_Pared() -> bool:
	return Tiempo_Sin_Pared <= Tiempo_Reaccion
