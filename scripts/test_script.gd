extends CharacterBody2D

# Velocidad de movimiento del personaje
const SPEED = 550

# Referencia al Sprite2D
@onready var sprite = $Sprite2D

# En el script del personaje
func _process(delta: float) -> void:
	var character_global_position = global_position

func _physics_process(delta: float) -> void:
	# Reiniciar la velocidad en cada frame
	velocity = Vector2.ZERO
	


	# Detectar entrada del usuario
	if Input.is_action_pressed("Derecha"):
		velocity.x += 1
	if Input.is_action_pressed("Izquierda"):
		velocity.x -= 1
	if Input.is_action_pressed("Abajo"):
		velocity.y += 1
	if Input.is_action_pressed("Arriba"):
		velocity.y -= 1

	# Normalizar el vector de movimiento para evitar que se mueva más rápido en diagonal
	if velocity.length() > 0:
		velocity = velocity.normalized() * SPEED

		# Rotar el sprite según la dirección del movimiento
		if velocity.x > 0:
			sprite.rotation_degrees = 0  # Mirando a la derecha
		elif velocity.x < 0:
			sprite.rotation_degrees = 180  # Mirando a la izquierda
		elif velocity.y > 0:
			sprite.rotation_degrees = 90  # Mirando hacia abajo
		elif velocity.y < 0:
			sprite.rotation_degrees = 270  # Mirando hacia arriba

	# Mover al personaje usando move_and_slide
	move_and_slide()
