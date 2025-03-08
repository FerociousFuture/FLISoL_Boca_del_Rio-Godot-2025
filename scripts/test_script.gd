extends CharacterBody2D

# Velocidad de movimiento del personaje
const SPEED = 300.0

# Referencia al AnimatedSprite2D
@onready var sprite = $Sprite2D

func _physics_process(delta: float) -> void:
	# Reiniciar la velocidad en cada frame
	velocity = Vector2.ZERO

	# Detectar entrada del usuario
	if Input.is_action_pressed("ui_right"):
		velocity.x += 1
	if Input.is_action_pressed("ui_left"):
		velocity.x -= 1
	if Input.is_action_pressed("ui_down"):
		velocity.y += 1
	if Input.is_action_pressed("ui_up"):
		velocity.y -= 1

	# Normalizar el vector de movimiento para evitar que se mueva más rápido en diagonal
	if velocity.length() > 0:
		velocity = velocity.normalized() * SPEED

		# Reproducir animación según la dirección
		if velocity.x > 0:
			sprite.play("Arriba")
		elif velocity.x < 0:
			sprite.play("Abajo")
		elif velocity.y > 0:
			sprite.play("Izquierda")
		elif velocity.y < 0:
			sprite.play("Derecha")
	else:
		# Detener la animación si no hay movimiento
		sprite.stop()

	# Mover al personaje usando move_and_slide
	move_and_slide()
