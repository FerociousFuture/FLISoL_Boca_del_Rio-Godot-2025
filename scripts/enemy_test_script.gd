extends CharacterBody2D

# Velocidad y aceleración del enemigo
var speed = 400
var accel = 7
var move_flag = true
var target: Node2D = null

# Referencia al NavigationAgent2D
@onready var nav = $NavigationAgent2D

# Referencia al jugador
@onready var player = $"../test_character"

# Referencia al ShapeCast2D
@onready var shape_cast = $ShapeCast2D

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

# Forma del cono (se crea una sola vez)
var cone_shape: ConvexPolygonShape2D

# Ángulo de rotación del cono de visión
var cone_rotation_angle = 0.0
var cone_rotation_speed = 1.0  # Velocidad de rotación del cono

# Variables para el comportamiento errático
var erratic_timer: float = 0.0
var erratic_direction: Vector2 = Vector2.ZERO
var erratic_interval: float = 2.0  # Intervalo de cambio de dirección

func _ready():
	# Configurar el NavigationAgent2D
	nav.max_speed = speed
	
	# Esperar a que el NavigationAgent2D esté listo
	await get_tree().process_frame
	is_nav_ready = true
	
	# Configurar el ShapeCast2D con forma de cono
	setup_cone_shape()
	
	# Configurar el Polygon2D para dibujar el cono de visión
	setup_vision_cone()

func setup_cone_shape():
	# Crear un ConvexPolygonShape2D para simular un cono (solo una vez)
	cone_shape = ConvexPolygonShape2D.new()
	
	# Definir los puntos del cono
	var cone_angle = deg_to_rad(45)  # Ángulo de apertura del cono (45 grados a cada lado)
	var cone_radius = 500.0          # Radio del cono
	var cone_points = []
	
	# Punto inicial (vértice del cono)
	cone_points.append(Vector2(0, 0))
	
	# Puntos del arco del cono
	for i in range(-45, 46, 5):  # Desde -45 grados hasta 45 grados
		var angle = deg_to_rad(i)
		var point = Vector2(cos(angle), sin(angle)) * cone_radius
		cone_points.append(point)
	
	# Asignar los puntos al ConvexPolygonShape2D
	cone_shape.points = cone_points
	
	# Asignar la forma al ShapeCast2D
	shape_cast.shape = cone_shape

func setup_vision_cone():
	# Configurar el Polygon2D para dibujar el cono de visión
	vision_cone.polygon = cone_shape.points
	vision_cone.color = Color.YELLOW  # Color inicial del cono (amarillo)

func _process(delta):
	# Manejar la entrada del usuario
	if Input.is_action_pressed("run"):
		move_flag = true
	if Input.is_action_just_pressed("Stop"):
		move_flag = false

func _physics_process(delta):
	if not is_nav_ready:
		return
		
	# Verificar si el ShapeCast2D detecta al jugador o una pared
	player_detected = false
	wall_detected = false

	# Forzar la actualización del ShapeCast2D
	shape_cast.force_shapecast_update()

	# Verificar colisiones con el ShapeCast2D
	if shape_cast.is_colliding():
		for i in range(shape_cast.get_collision_count()):
			var collider = shape_cast.get_collider(i)
			if collider == player:
				player_detected = true
				player_in_cone = true
				print("Jugador detectado!")
			elif collider is TileMap:  # Verificar si es un TileMap (pared)
				wall_detected = true
				print("Pared detectada!")
				break  # Salir del bucle si se detecta una pared

	# Si el jugador no está en el cono, pero estaba previamente, reiniciar la búsqueda
	if not player_detected and player_in_cone:
		player_in_cone = false
		print("Jugador salió del cono de visión.")

	# Comportamiento del cono de visión
	if player_in_cone and not wall_detected:
		# Apuntar el cono hacia el jugador
		shape_cast.look_at(player.global_position)
		vision_cone.look_at(player.global_position)
		
		# Guardar la última posición conocida del jugador
		last_known_player_position = player.global_position
		
		# Cambiar el color del cono a rojo
		vision_cone.color = Color.RED
	else:
		# Si el jugador no está en el cono, mantener la dirección hacia la última posición conocida
		if last_known_player_position != Vector2.ZERO:
			shape_cast.look_at(last_known_player_position)
			vision_cone.look_at(last_known_player_position)
		else:
			# Rotar el cono de visión si no hay detección ni última posición conocida
			cone_rotation_angle += cone_rotation_speed * delta
			shape_cast.global_rotation = cone_rotation_angle
			vision_cone.global_rotation = cone_rotation_angle
		
		# Cambiar el color del cono a amarillo
		vision_cone.color = Color.GREEN

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
