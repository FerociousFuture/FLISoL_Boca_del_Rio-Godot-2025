extends CharacterBody2D

# Velocidad y aceleración del enemigo
var speed = 400
var accel = 7
var move_flag = true

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

func _process(delta):
	# Actualizar la posición objetivo del NavigationAgent2D
	nav.target_position = player.global_position

	# Manejar la entrada del usuario
	if Input.is_action_pressed("run"):
		move_flag = true
	if Input.is_action_just_pressed("Stop"):
		move_flag = false

func _physics_process(delta):
	if not is_nav_ready:
		return

	if nav.is_navigation_finished():
		return

	var next_path_position = nav.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	velocity = velocity.lerp(direction * speed, accel * delta)

	if move_flag:
		move_and_slide()
