class_name TestCamera
extends Node3D

@export var speed : float = 10.0
@export var mouse_sensitivity : float = 0.002
@export var speed_step : float = 2.0
@export var min_speed : float = 1.0
@export var max_speed : float = 100.0

@onready var cam : Camera3D = $Camera3D

var move_speed : float = 10.0

var pitch : float = 0.0

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		
		pitch -= event.relative.y * mouse_sensitivity
		pitch = clamp(pitch, deg_to_rad(-89.0), deg_to_rad(89.0))
		cam.rotation.x = pitch
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			move_speed = clamp(move_speed + speed_step, min_speed, max_speed)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			move_speed = clamp(move_speed - speed_step, min_speed, max_speed)

func _process(delta):
	var move_dir := Vector3.ZERO
	var forward := -global_transform.basis.z
	var right := global_transform.basis.x
	
	forward.y = 0.0
	right.y = 0.0
	forward = forward.normalized()
	right = right.normalized()
	
	if Input.is_key_pressed(KEY_W):
		move_dir += forward
	if Input.is_key_pressed(KEY_S):
		move_dir -= forward
	if Input.is_key_pressed(KEY_D):
		move_dir += right
	if Input.is_key_pressed(KEY_A):
		move_dir -= right
	
	if Input.is_key_pressed(KEY_SPACE):
		move_dir += Vector3.UP
	if Input.is_key_pressed(KEY_CTRL):
		move_dir += Vector3.DOWN
	
	if move_dir != Vector3.ZERO:
		move_dir = move_dir.normalized()
		global_position += move_dir * move_speed * delta
