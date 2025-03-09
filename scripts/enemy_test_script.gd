extends CharacterBody2D

# Velocidad y aceleración del enemigo
var speed = 300
var accel = 7

# Referencia al NavigationAgent2D
@onready var nav = $NavigationAgent2D

# Referencia al jugador
@onready var player = $"../test_character"

# Variable para verificar si el NavigationAgent2D está listo
var is_nav_ready = false

func _ready():
	# Configurar el NavigationAgent2D
	nav.max_speed = speed
	
	# Esperar a que el NavigationAgent2D esté listo
	await get_tree().process_frame
	is_nav_ready = true
	nav.target_position = player.global_position

func _physics_process(delta):
	# Si el NavigationAgent2D no está listo, no hacer nada
	if not is_nav_ready:
		return

	# Actualizar la posición objetivo del NavigationAgent2D
	nav.target_position = player.global_position

	# Verificar si hay una ruta válida
	if nav.is_navigation_finished():
		return

	# Obtener la siguiente posición en la ruta
	var next_path_position = nav.get_next_path_position()

	# Calcular la dirección hacia la siguiente posición
	var direction = (next_path_position - global_position).normalized()

	# Suavizar el movimiento usando lerp
	velocity = velocity.lerp(direction * speed, accel * delta)

	# Mover al enemigo usando move_and_slide
	move_and_slide()
