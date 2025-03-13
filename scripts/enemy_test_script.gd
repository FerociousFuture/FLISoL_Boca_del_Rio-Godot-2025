extends CharacterBody2D

# Velocidad y aceleración del enemigo
var speed = 500
var accel = 7
var move_flag = true

# Referencia al NavigationAgent2D
@onready var nav = $NavigationAgent2D

# Referencia al jugador
@onready var player = $"../test_character"

# Referencia al nodo padre de los RayCast2D
@onready var raycasts = $Node2D.get_children()

# Referencia al Polygon2D para dibujar el cono de visión
@onready var vision_cone = $Polygon2D

# Variable para verificar si el NavigationAgent2D está listo
var is_nav_ready = false

# Variable para verificar si el jugador ha sido detectado
var player_detected = false

# Variable para verificar si hay una pared en el camino
var wall_detected = false

# Variable para verificar si el jugador está dentro del cono de visión
var player_in_cone = false

# Última posición conocida del jugador
var last_known_player_position: Vector2 = Vector2.ZERO

# Variables para el comportamiento errático
var erratic_timer: float = 0.0
var erratic_direction: Vector2 = Vector2.ZERO
var erratic_interval: float = 2.0  # Intervalo de cambio de dirección

# Longitud de los RayCast2D
var ray_length = 400

func _ready():
	# Configurar el NavigationAgent2D
	nav.max_speed = speed
	
	# Esperar a que el NavigationAgent2D esté listo
	await get_tree().process_frame
	is_nav_ready = true
	
	# Configurar el Polygon2D para dibujar el cono de visión
	setup_vision_cone()
	
	# Configurar la longitud de los RayCast2D
	for raycast in raycasts:
		raycast.target_position = Vector2(0, -ray_length).rotated(raycast.rotation)
		print(raycast.name, " - Target Position: ", raycast.target_position)

func setup_vision_cone():
	# Configurar el Polygon2D para dibujar el cono de visión
	vision_cone.color = Color(1, 1, 0, 0.3)  # Amarillo semitransparente

func update_vision_cone():
	# Crear un arco para el cono de visión
	var cone_points = []
	var ray_count = raycasts.size()  # Número de RayCast2D

	# Punto inicial (vértice del cono)
	cone_points.append(Vector2.ZERO)

	# Calcular los puntos del arco del cono
	for i in range(ray_count):
		var raycast = raycasts[i]
		var ray_direction = raycast.target_position.normalized()
		var ray_end = ray_direction * ray_length
		cone_points.append(ray_end)

	# Cerrar el polígono
	cone_points.append(Vector2.ZERO)

	# Asignar los puntos al Polygon2D
	vision_cone.polygon = cone_points

func update_raycasts_rotation():
	# Actualizar la rotación de los RayCast2D según la dirección del enemigo
	var direction = (nav.get_next_path_position() - global_position).normalized()
	if direction != Vector2.ZERO:
		for raycast in raycasts:
			raycast.rotation = direction.angle() + raycast.rotation  # Mantener el ángulo relativo
			raycast.target_position = Vector2(0, -ray_length).rotated(raycast.rotation)

func _process(delta):
	# Manejar la entrada del usuario
	if Input.is_action_pressed("run"):
		move_flag = true
	if Input.is_action_just_pressed("Stop"):
		move_flag = false

func _physics_process(delta):
	if not is_nav_ready:
		return
		
	# Reiniciar las variables de detección
	player_detected = false
	wall_detected = false

	# Actualizar la rotación de los RayCast2D
	update_raycasts_rotation()

	# Verificar colisiones con los RayCast2D
	for raycast in raycasts:
		raycast.force_raycast_update()  # Forzar la actualización del RayCast2D
		if raycast.is_colliding():
			var collider = raycast.get_collider()
			if collider is TileMap:  # Verificar si es un TileMap (pared)
				wall_detected = true
				if not wall_detected:  # Solo imprimir una vez
					print("Pared detectada!")
				break  # Salir del bucle si se detecta una pared
			elif collider == player and not wall_detected:
				player_detected = true
				if not player_in_cone:  # Solo imprimir si el jugador no estaba previamente en el cono
					player_in_cone = true
					print("Jugador detectado!")

	# Si el jugador no está en el cono, pero estaba previamente, reiniciar la búsqueda
	if not player_detected and player_in_cone:
		player_in_cone = false
		print("Jugador salió del cono de visión.")

	# Comportamiento del cono de visión
	if player_in_cone and not wall_detected:
		# Apuntar el cono hacia el jugador
		vision_cone.look_at(player.global_position)
		
		# Guardar la última posición conocida del jugador
		last_known_player_position = player.global_position
		
		# Cambiar el color del cono a rojo
		vision_cone.color = Color(1, 0, 0, 0.3)  # Rojo semitransparente
	else:
		# Si el jugador no está en el cono, mantener la dirección hacia la última posición conocida
		if last_known_player_position != Vector2.ZERO:
			vision_cone.look_at(last_known_player_position)
		else:
			# Alinear el cono de visión con la dirección del movimiento
			var direction = (nav.get_next_path_position() - global_position).normalized()
			if direction != Vector2.ZERO:
				vision_cone.rotation = direction.angle()
		
		# Cambiar el color del cono a amarillo
		vision_cone.color = Color(1, 1, 0, 0.3)  # Amarillo semitransparente

	# Actualizar el cono de visión
	update_vision_cone()

	# Comportamiento del enemigo
	if player_in_cone and not wall_detected:
		# Si el jugador está en el cono y no hay pared, seguir al jugador
		nav.target_position = last_known_player_position
	else:
		# Si el jugador no está en el cono o hay una pared, moverse hacia la última posición conocida
		if last_known_player_position != Vector2.ZERO:
			nav.target_position = last_known_player_position
		else:
			# Comportamiento errático cuando no hay jugador ni última posición conocida
			erratic_timer += delta
			if erratic_timer >= erratic_interval:
				erratic_timer = 0.0
				erratic_direction = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
				nav.target_position = global_position + erratic_direction * 200  # Mover en una dirección aleatoria

	if nav.is_navigation_finished():
		last_known_player_position = Vector2.ZERO  # Reiniciar la última posición conocida
		print("Llegó al último punto conocido.")
		return

	var next_path_position = nav.get_next_path_position()
	var direction = (next_path_position - global_position).normalized()
	velocity = velocity.lerp(direction * speed, accel * delta)

	if move_flag:
		move_and_slide()
