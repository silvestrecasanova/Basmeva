# Base modular de personaje 2D (Basmeva) – Godot 4

Prototipo de Basmeva 2D en **Godot 4 (GDScript)**. Probado en 4.3; requiere 4.2 o superior.
Es una base **modular**: el personaje se compone de gestores y de **habilidades independientes**
que se agregan o quitan sin modificar el resto. Más adelante se irán sumando habilidades y otros
sistemas del juego (inventario, enemigos, combate, guardado de partida...).

> **Para la IA que lea esto:** lee primero este archivo, luego `Personaje/Nucleo/Habilidad_Base.gd`
> y `Personaje/Personaje.gd`. No hace falta más para entender la arquitectura. Entrega siempre
> archivos completos y no agregues funcionalidades que no se pidan.

## Qué hace hoy
- Habilidades: **caminar, salto, doble salto, dash, bajar plataforma** (mantener abajo + saltar).
- Suelo sólido y plataformas unidireccionales (se atraviesan de abajo hacia arriba).
- Escena de pruebas con cuadrícula verde, plataformas a distintas alturas y paredes.
- Cuadrícula visual configurable (`@tool`, se ve en el editor).
- Panel de depuración en modo juego para ver y editar valores y guardar el JSON.
- Configuración en un único `Config.json`; cada habilidad aporta su propia porción.
 
**Fuera por ahora:** inventario, enemigos, combate, partida guardada, desbloqueo por progreso,
remapeo de botones por el jugador.

## Estructura
```
Personaje/
├── Personaje.gd              Script principal (CharacterBody2D): variables generales y orden de ejecución
├── Config.json               Valores del personaje y de cada habilidad
├── Escenas/Personaje.tscn    Personaje, Sprite2D, CollisionShape2D (32x64) y nodo Gestores
├── Sprites/
├── Nucleo/
│   ├── Habilidad_Base.gd     Clase base de toda habilidad (interfaz común)
│   ├── Gestor_Acciones.gd    Lee el Input Map y expone la intención del jugador
│   ├── Gestor_Habilidades.gd Crea, registra y actualiza habilidades; coordina incompatibilidades
│   └── Gestor_Fisico.gd      Gravedad, velocidad y move_and_slide()
└── Habilidades/              Caminar, Salto, Doble_Salto, Dash, Bajar_Plataforma
Herramientas/
├── Guia_Rejilla.gd           Cuadrícula visual (@tool)
├── Gestor_Config.gd          Lee y guarda Config.json del personaje
└── Panel_Depuracion.gd       Panel de depuración en modo juego (solo pruebas)
Escenarios/Prueba.tscn        Escena de pruebas
```

## Orden de ejecución (cada frame de físicas, en `Personaje._physics_process`)
1. `Acciones.Actualizar` – lee la dirección horizontal.
2. `Fisica.Aplicar_Gravedad` – salvo que una habilidad activa la anule.
3. `Habilidades.Actualizar` – cada habilidad desbloqueada revisa entradas/estado y actúa.
4. `Fisica.Mover` – único `move_and_slide()`; emite `Aterrizo` / `Salio_Del_Suelo`.

Solo `Personaje.gd` tiene bucle de físicas; los demás nodos no.

## Módulos
- **Habilidad_Base**: define `Nombre`, `Dueno` (el personaje), `Habilitada`, `Activa`, `Anula_Gravedad`,
  `Bloquea_Otras`, `Parametros`. Interfaz: `Inicializar(personaje)`, `Activar()`, `Actualizar(delta)`,
  `Desactivar()`. Config: `Parametros_Por_Defecto()`, `Acciones_Por_Defecto()`, `Al_Cambiar_Config()`.
  Utilidades: `Intentar_Activar(instantanea)`, `Terminar()`, `Registrar_Funcion(nombre, callable)`.
- **Gestor_Habilidades**: `Scripts_Habilidades` (array exportado en el Inspector) = habilidades que el
  jugador tiene al empezar (puede estar vacío). Mantiene `Lista` (todas) y `Lista_Activa` (solo las
  habilitadas, la única que recorre cada frame). Desbloquear en partida: `Agregar_Script(script)`.
  También: `Quitar_Habilidad`, `Habilitar`, `Obtener`, `Solicitar_Activacion/Fin`, `Gravedad_Anulada`.
  Registro de funciones por `Callable`: `Registrar_Funcion`, `Ejecutar_Funcion("dash.Esta_Activo")`.
- **Gestor_Acciones**: `Direccion_Horizontal`, `Presionada/Recien_Presionada/Soltada(accion)`,
  `Entradas_Activas`, `Registrar_Accion` (crea la acción en el Input Map solo si no existe).
- **Gestor_Fisico**: `En_Suelo`, `Establecer_Velocidad(_X/_Y)`. Las habilidades **no** llaman a
  `move_and_slide()`.
- **Personaje**: `Gravedad`, `Energia`, `Direccion_Mirada`, `Parametros`, `Config`; accesos
  `Acciones`, `Habilidades`, `Fisica`; `Guardar_Config()`.

## Habilidades actuales
| Nombre | Acción (Input Map) | Parámetros en JSON | Notas |
|---|---|---|---|
| caminar | mover_izquierda / mover_derecha (A/D, flechas) | velocidad | |
| salto | saltar (Espacio, W, ↑) | fuerza | solo desde el suelo |
| doble_salto | saltar | cantidad, fuerza | `cantidad` = saltos totales antes de tocar el suelo; despegar cuenta como el primero |
| dash | dash (Shift, K) | velocidad, duracion, recuperacion | anula gravedad y bloquea otras habilidades mientras dura |
| bajar_plataforma | abajo + saltar (S/↓) | tiempo_caida | debe ir **después** de `salto` en la lista |

## Config.json
```json
{ "personaje": { "gravedad": 1200.0, "energia": 100.0 },
  "habilidades": { "dash": { "habilitada": true, "velocidad": 700.0, "duracion": 0.2, "recuperacion": 0.4 } } }
```
- Cada habilidad aporta su sección (`Obtener_Config()`); no hay código de guardado por habilidad.
- **Solo se escribe desde el editor** (`OS.has_feature("editor")`). Si falta algo (habilidad nueva,
  archivo borrado), el editor lo completa solo al ejecutar. La **build solo lee**; sin archivo usa los
  valores por defecto de cada script.
- La ruta está en `Gestor_Config.Ruta_Archivo` (`res://Personaje/Config.json`).
- Al exportar, añadir `*.json` en Exportar > Recursos > filtros de archivos que no son recursos.
- Los ajustes del jugador (botones, etc.) irían en `user://`, no en este JSON.

## Cómo agregar una habilidad
1. Crear un script que extienda `Habilidad_Base` (sin tocar ningún otro script).
2. En `_init()` definir `Nombre`; sobreescribir `Parametros_Por_Defecto`, `Acciones_Por_Defecto`,
   `Al_Cambiar_Config` (copiar parámetros a variables tipadas) y `Actualizar` (+ `Activar/Desactivar` si hace falta).
3. Arrastrar el script a `Scripts_Habilidades` en el nodo `Gestores/Gestor_Habilidades` de `Personaje.tscn`
   (o llamar a `Agregar_Script` en tiempo de juego).
4. Ejecutar una vez desde el editor: el JSON y el panel de depuración se completan solos.

Si es una acción instantánea usar `Intentar_Activar(true)`; si dura, `Intentar_Activar()` y `Terminar()`.
Para anular gravedad o bloquear a las demás: `Anula_Gravedad` / `Bloquea_Otras` = true en `_init()`.

## Escena de pruebas y suelos
- Suelo sólido: `StaticBody2D` + `CollisionShape2D`, grupo `suelo`.
- Plataforma unidireccional: igual con `One Way Collision` activado, grupo `unidireccional`.
- Los suelos se colocan directamente en el escenario (sin escena por suelo); las formas deben ser únicas.
- Capas de colisión: mundo = capa 1; personaje = capa 2, máscara 1.
- Cuadrícula: celda de 32 px, 36x21. El personaje mide 1x2 celdas. Un salto sube unos 88 px (~2,7 celdas).
- Un tipo de suelo nuevo con comportamiento propio (hielo, daño...) se logra con un grupo nuevo que una
  habilidad consulte, como `bajar_plataforma` consulta `unidireccional`.

## Panel de depuración (`Herramientas/Panel_Depuracion.gd`)
Botón **Variables**: estado del personaje y valores editables; selector de habilidad para editar sus
valores en vivo (incluida la casilla `habilitada`); botón **Guardar Config.json** (solo en el editor).
Se construye con lo que cada habilidad expone, no hay que editarlo al agregar habilidades.
Por defecto solo existe al ejecutar desde el editor (`Solo_En_Editor`). Mientras se escribe en un
campo, el personaje no recibe teclas.

## Convenciones
- Funciones y clases en **Pascal_Case** (`Inicializar`, `Gestor_Fisico`); variables descriptivas **en español**.
  Los callbacks de Godot conservan su nombre (`_ready`, `_physics_process`, `_draw`).
- Sangría con tabulaciones. GDScript tipado. Sin `call()` con nombres en texto cuando hay referencia tipada.
- Evitar nombres que sombreen clases nativas de Godot (por ejemplo `Panel`).
- Comunicación: referencias directas tipadas, señales para eventos, `Callable` para funciones registradas
  con nombre `"habilidad.funcion"`.

## Decisiones de diseño
- Las habilidades son **nodos hijos** de `Gestor_Habilidades` creados desde scripts del Inspector; no se
  escanea la carpeta (fallaría en la build exportada).
- Cada valor vive en un solo sitio: lo general en el personaje, lo específico en su habilidad.
- El gestor solo conoce `Habilidad_Base`; cada habilidad decide en `Actualizar` si actúa.
- Los bloqueos entre habilidades se declaran con banderas, no con lógica especial.

## Pendiente / siguientes pasos
- Sistema de partida guardada que cargue las habilidades desbloqueadas (usando `Agregar_Script`).
- Remapeo de botones (`InputMap` + guardado en `user://`).
- Más habilidades y, después, inventario, enemigos y combate.
