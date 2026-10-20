class_name LevelController
extends Node3D

@export var player : Node3D

@export var cells : Array[Cell] = []
@export var chunk_scene : PackedScene

@export var edge_connections_weights : Dictionary[int, float] = {}

@export var chunk_size : int = 10
@export var tile_size : float = 6.0

@export var load_radius : int = 2
@export var unload_radius : int = 3

@export var world_seed : int = 12345

var active_chunks : Dictionary = {}

var current_player_chunk: Vector2i = Vector2i(999999, 999999)

var chunk_queue : Array[Vector2i] = []

var chunk_world_size : float = 0

var edge_types : Array[int] = []
var edge_weights : PackedFloat32Array = PackedFloat32Array()

func _ready() -> void:
	setup_level()

func setup_level() -> void:
	chunk_world_size = chunk_size * tile_size
	
	edge_types = edge_connections_weights.keys()
	edge_types.sort()
	
	for type in edge_types:
		edge_weights.append(edge_connections_weights[type])

func _process(_delta: float) -> void:
	if player == null:
		return
	
	var player_chunk : Vector2i = get_player_chunk()
	
	if player_chunk != current_player_chunk:
		update_chunks()
	
	process_chunk_queue()

func get_player_chunk() -> Vector2i:
	return Vector2i(
		floor(player.global_position.x / chunk_world_size),
		floor(player.global_position.z / chunk_world_size)
	)

func update_chunks(force : bool = false) -> void:
	var center : Vector2i = get_player_chunk()
	
	if not force and center == current_player_chunk:
		return
	
	current_player_chunk = center
	load_chunks_around(center)
	unload_far_chunks(center)

func load_chunks_around(center : Vector2i) -> void:
	for x in range(center.x - load_radius, center.x + load_radius + 1):
		for y in range(center.y - load_radius, center.y + load_radius + 1):
			var chunk_coord : Vector2i = Vector2i(x, y)
			
			if active_chunks.has(chunk_coord):
				continue
			
			if chunk_coord in chunk_queue:
				continue
			
			chunk_queue.append(chunk_coord)
			
			chunk_queue.sort_custom(
				func(a, b):
				return a.distance_squared_to(center) < b.distance_squared_to(center)
			)

func process_chunk_queue() -> void:
	if chunk_queue.is_empty():
		return
	
	for c in active_chunks:
		if active_chunks[c].generating:
			return
	
	var coord : Vector2i = chunk_queue.pop_front()
		
	if not active_chunks.has(coord):
		create_chunk(coord)

func unload_far_chunks(center: Vector2i) -> void:
	var to_remove : Array[Vector2i] = []
	
	for chunk_coord in active_chunks.keys():
		var dx : int = abs(chunk_coord.x - center.x)
		var dy : int = abs(chunk_coord.y - center.y)
		
		if dx > unload_radius or dy > unload_radius:
			var chunk = active_chunks[chunk_coord]
			
			if is_instance_valid(chunk):
				chunk.queue_free()
			to_remove.append(chunk_coord)
	
	for chunk_coord in to_remove:
		active_chunks.erase(chunk_coord)

func create_chunk(chunk_coord: Vector2i) -> void:
	var chunk = chunk_scene.instantiate()
	add_child(chunk)
	
	chunk.position = Vector3(
		chunk_coord.x * chunk_world_size, 
		0, 
		chunk_coord.y * chunk_world_size
	)
	
	var chunk_seed := get_chunk_seed(chunk_coord)
	
	chunk.setup(self, chunk_coord, chunk_size, tile_size, chunk_seed)
	
	active_chunks[chunk_coord] = chunk

func get_all_valid_points() -> Array[Vector3]:
	var all_points : Array[Vector3] = []
	
	for c in active_chunks.keys():
		all_points.append_array(active_chunks[c].valid_points)
	
	return all_points

func get_edge_connections(a : Vector2i, b : Vector2i) -> Array[int]:
	if edge_connections_weights.size() == 0:
		return []
	
	var delta: Vector2i = b - a
	
	if absi(delta.x) + absi(delta.y) != 1:
		return []
	
	var anchor : Vector2i = Vector2i(mini(a.x, b.x), mini(a.y, b.y))
	var axis : int = 0 if delta.x != 0 else 1
	
	var seed_string := "%d_%d_%d_%d" % [world_seed, anchor.x, anchor.y, axis]
	
	var edge_rng : RandomNumberGenerator = RandomNumberGenerator.new()
	edge_rng.seed = hash(seed_string)
	
	var result : Array[int] = []
	
	for i in range(chunk_size):
		result.append(edge_types[edge_rng.rand_weighted(edge_weights)])
	
	return result

func global_cell_to_chunk(cell: Vector2i) -> Vector2i:
	return Vector2i(
		floori(float(cell.x) / chunk_size),
		floori(float(cell.y) / chunk_size)
	)

func get_chunk_seed(chunk_coord: Vector2i) -> int:
	var hash_input : String = str(world_seed) + "_" + str(chunk_coord.x) + "_" + str(chunk_coord.y)
	return hash(hash_input)
