extends CharacterBody2D

# Velocidad de movimiento del enemigo
const SPEED = 200.0

# Referencia al NavigationAgent2D
@onready var navigation_agent = $NavigationAgent2D

# Referencia al personaje principal (asignado desde el editor o buscado en código)
@onready var player = get_tree().get_root().get_node("test_chamber/test_character")

func _ready():
	# Conectar la señal de "target_reached" para manejar cuándo el enemigo llega al objetivo
	navigation_agent.target_reached.connect(_on_target_reached)

func _physics_process(delta: float) -> void:
	# Verificar si el NavigationAgent tiene un objetivo
	if navigation_agent.is_navigation_finished():
		return

	# Obtener la siguiente posición del camino hacia el objetivo
	var next_path_position = navigation_agent.get_next_path_position()

	# Calcular la dirección hacia la siguiente posición
	var direction = (next_path_position - global_position).normalized()

	# Mover al enemigo en la dirección calculada
	velocity = direction * SPEED

	# Mover al enemigo usando move_and_slide
	move_and_slide()

func set_target(target_position: Vector2):
	# Establecer la posición objetivo en el NavigationAgent
	navigation_agent.target_position = target_position

func _on_target_reached():
	# Lógica para cuando el enemigo alcanza al jugador
	print("¡Enemigo alcanzó al jugador!")
