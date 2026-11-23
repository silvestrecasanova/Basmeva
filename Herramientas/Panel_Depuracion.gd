extends CanvasLayer
## Panel de depuración para el modo juego.
## Botón "Variables": muestra el estado y los valores del personaje y, debajo,
## un selector de habilidad para ver y modificar sus valores en vivo.
## Botón "Guardar Config.json": escribe todos los valores (solo funciona en el editor).
## No hay que editarlo al agregar habilidades: se construye con lo que cada una expone.

## Si es true, el panel solo existe al ejecutar desde el editor.
@export var Solo_En_Editor: bool = true

var Personaje_Ref: Personaje
var Boton_Mostrar: Button
var Panel_Variables: PanelContainer
var Etiqueta_Estado: Label
var Contenedor_Personaje: VBoxContainer
var Selector: OptionButton
var Contenedor_Habilidad: VBoxContainer
var Etiqueta_Mensaje: Label
var Foco_En_Texto: bool = false


func _ready() -> void:
	layer = 100
	if Solo_En_Editor and not Gestor_Config.En_Editor():
		queue_free()
		return
	# Se espera un frame para que el personaje ya esté listo.
	await get_tree().process_frame
	Personaje_Ref = get_tree().get_first_node_in_group("personaje") as Personaje
	if Personaje_Ref == null:
		push_warning("Panel_Depuracion: no se encontró un Personaje en la escena.")
		queue_free()
		return
	Construir_Interfaz()
	Crear_Editores(Contenedor_Personaje, Personaje_Ref.Parametros, Personaje_Ref.Establecer_Parametro)
	Llenar_Selector()


func _process(_delta: float) -> void:
	if Personaje_Ref == null or Panel_Variables == null:
		return

	# Mientras se escribe en un campo, el personaje no recibe entradas.
	var escribiendo: bool = get_viewport().gui_get_focus_owner() is LineEdit
	if escribiendo != Foco_En_Texto:
		Foco_En_Texto = escribiendo
		Personaje_Ref.Acciones.Entradas_Activas = not escribiendo

	if not Panel_Variables.visible:
		return
	var activas: PackedStringArray = []
	for habilidad in Personaje_Ref.Habilidades.Lista:
		if habilidad.Activa:
			activas.append(habilidad.Nombre)
	Etiqueta_Estado.text = "Velocidad: (%.0f, %.0f)\nEn suelo: %s   Mirando: %s\nActivas: %s" % [
		Personaje_Ref.velocity.x,
		Personaje_Ref.velocity.y,
		"sí" if Personaje_Ref.Fisica.En_Suelo else "no",
		"derecha" if Personaje_Ref.Direccion_Mirada > 0 else "izquierda",
		", ".join(activas) if not activas.is_empty() else "-",
	]


func _unhandled_input(evento: InputEvent) -> void:
	# Un clic fuera del panel quita el foco de los campos de texto.
	if evento is InputEventMouseButton and evento.pressed:
		var foco: Control = get_viewport().gui_get_focus_owner()
		if foco != null:
			foco.release_focus()


# ---------------------------------------------------------------------------
# Construcción de la interfaz
# ---------------------------------------------------------------------------

func Construir_Interfaz() -> void:
	Boton_Mostrar = Button.new()
	Boton_Mostrar.text = "Variables"
	Boton_Mostrar.toggle_mode = true
	Boton_Mostrar.focus_mode = Control.FOCUS_NONE
	Boton_Mostrar.position = Vector2(8, 8)
	Boton_Mostrar.toggled.connect(Al_Alternar_Panel)
	add_child(Boton_Mostrar)

	Panel_Variables = PanelContainer.new()
	Panel_Variables.position = Vector2(8, 44)
	Panel_Variables.visible = false
	add_child(Panel_Variables)

	var desplazable := ScrollContainer.new()
	desplazable.custom_minimum_size = Vector2(400, 460)
	Panel_Variables.add_child(desplazable)

	var columna := VBoxContainer.new()
	columna.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desplazable.add_child(columna)

	columna.add_child(Crear_Titulo("PERSONAJE"))
	Etiqueta_Estado = Label.new()
	columna.add_child(Etiqueta_Estado)
	Contenedor_Personaje = VBoxContainer.new()
	columna.add_child(Contenedor_Personaje)

	columna.add_child(HSeparator.new())
	columna.add_child(Crear_Titulo("HABILIDAD"))
	Selector = OptionButton.new()
	Selector.focus_mode = Control.FOCUS_NONE
	Selector.item_selected.connect(Mostrar_Habilidad)
	columna.add_child(Selector)
	Contenedor_Habilidad = VBoxContainer.new()
	columna.add_child(Contenedor_Habilidad)

	columna.add_child(HSeparator.new())
	var boton_guardar := Button.new()
	boton_guardar.text = "Guardar Config.json"
	boton_guardar.focus_mode = Control.FOCUS_NONE
	boton_guardar.pressed.connect(Al_Guardar)
	columna.add_child(boton_guardar)
	Etiqueta_Mensaje = Label.new()
	columna.add_child(Etiqueta_Mensaje)


func Crear_Titulo(texto: String) -> Label:
	var titulo := Label.new()
	titulo.text = texto
	titulo.add_theme_color_override("font_color", Color(0.6, 1.0, 0.7))
	return titulo


## Crea una fila editable por cada valor del diccionario (bool, int o float).
## al_cambiar se llama como al_cambiar(clave, valor).
func Crear_Editores(contenedor: VBoxContainer, parametros: Dictionary, al_cambiar: Callable) -> void:
	for clave in parametros:
		var valor: Variant = parametros[clave]
		var fila := HBoxContainer.new()
		var etiqueta := Label.new()
		etiqueta.text = str(clave)
		etiqueta.custom_minimum_size.x = 150
		fila.add_child(etiqueta)

		if valor is bool:
			var casilla := CheckBox.new()
			casilla.button_pressed = valor
			casilla.focus_mode = Control.FOCUS_NONE
			casilla.toggled.connect(func(activo: bool) -> void: al_cambiar.call(clave, activo))
			fila.add_child(casilla)
		elif valor is float or valor is int:
			var campo := SpinBox.new()
			campo.min_value = -100000.0
			campo.max_value = 100000.0
			campo.step = 0.01
			campo.value = float(valor)
			campo.custom_minimum_size.x = 150
			campo.value_changed.connect(func(nuevo: float) -> void: al_cambiar.call(clave, nuevo))
			fila.add_child(campo)
		else:
			var texto := Label.new()
			texto.text = str(valor)
			fila.add_child(texto)

		contenedor.add_child(fila)


func Limpiar(contenedor: Container) -> void:
	for hijo in contenedor.get_children():
		contenedor.remove_child(hijo)
		hijo.queue_free()


func Llenar_Selector() -> void:
	Selector.clear()
	for habilidad in Personaje_Ref.Habilidades.Lista:
		Selector.add_item(habilidad.Nombre)
	if Selector.item_count > 0:
		Selector.select(0)
		Mostrar_Habilidad(0)


# ---------------------------------------------------------------------------
# Eventos
# ---------------------------------------------------------------------------

func Al_Alternar_Panel(activo: bool) -> void:
	Panel_Variables.visible = activo


func Mostrar_Habilidad(indice: int) -> void:
	Limpiar(Contenedor_Habilidad)
	var nombre: String = Selector.get_item_text(indice)
	var habilidad: Habilidad_Base = Personaje_Ref.Habilidades.Obtener(nombre)
	if habilidad == null:
		return
	var datos: Dictionary = {"habilitada": habilidad.Habilitada}
	datos.merge(habilidad.Parametros)
	Crear_Editores(Contenedor_Habilidad, datos, Aplicar_Valor_Habilidad.bind(nombre))


func Aplicar_Valor_Habilidad(clave: String, valor: Variant, nombre: String) -> void:
	if clave == "habilitada":
		Personaje_Ref.Habilidades.Habilitar(nombre, bool(valor))
		return
	var habilidad: Habilidad_Base = Personaje_Ref.Habilidades.Obtener(nombre)
	if habilidad != null:
		habilidad.Establecer_Parametro(clave, valor)


func Al_Guardar() -> void:
	if Personaje_Ref.Guardar_Config():
		Etiqueta_Mensaje.text = "Config.json guardado."
	else:
		Etiqueta_Mensaje.text = "No se pudo guardar (solo funciona desde el editor)."
