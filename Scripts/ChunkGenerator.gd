class_name ChunkGenerator
extends Node3D

@export var connection_rule : ConnectionRule

@export var spawn_batch_size : int = 5

var chunk_coord : Vector2i
var chunk_size : int = 0
var tile_size : float = 0.0

var level_controller : LevelController = null

var variants : Array[CellVariant] = []
var rng : RandomNumberGenerator = RandomNumberGenerator.new()

var grid = []

var valid_points : Array[Vector3]

var north_edge : Array[int] = []
var east_edge : Array[int] = []
var south_edge : Array[int] = []
var west_edge : Array[int] = []

func setup(controller : LevelController, coord: Vector2i, size_value: int, tile_value: float, seed_value: int) -> void:
	chunk_coord = coord
	chunk_size = size_value
	tile_size = tile_value
	
	rng.seed = seed_value
	level_controller = controller
	
	connection_rule.build_lookup()
	
	get_edges()
	generate_variants()
	generate_chunk()

func get_edges() -> void:
	north_edge = level_controller.get_edge_connections(chunk_coord, chunk_coord + Vector2i.UP)
	east_edge = level_controller.get_edge_connections(chunk_coord, chunk_coord + Vector2i.RIGHT)
	south_edge = level_controller.get_edge_connections(chunk_coord, chunk_coord + Vector2i.DOWN)
	west_edge = level_controller.get_edge_connections(chunk_coord, chunk_coord + Vector2i.LEFT)

func generate_variants() -> void:
	variants.clear()
	
	for cell in level_controller.cells:
		if cell.can_rotate:
			for i in range(4):
				variants.append(CellVariant.new(cell, i))
		else:
			variants.append(CellVariant.new(cell, 0))

func generate_chunk() -> void:
	var success : bool = try_generate()
	
	if not success:
		push_error("Chunk generation failed at chunk %s" % chunk_coord)

func try_generate() -> bool:
	grid.clear()
	
	for x in range(chunk_size):
		grid.append([])
		
		for y in range(chunk_size):
			grid[x].append(null)
	
	var success : bool = generate_positions()
	
	if success:
		spawn_chunk()
		
	return success

func generate_positions() -> bool:
	var selection : Dictionary = find_next_cell()
	
	if selection.is_empty():
		return true
	
	var pos : Vector2i = selection["pos"]
	var valid : Array[CellVariant] = selection["valid"]
	
	if valid.is_empty():
		return false
	
	valid = shuffle_variants(valid)
	
	for v in valid:
		grid[pos.x][pos.y] = v
		
		if check_future_neighbors(pos) and generate_positions():
			return true
		
		grid[pos.x][pos.y] = null
	
	return false

func find_next_cell() -> Dictionary:
	var best_pos : Vector2i = Vector2i(-1, -1)
	var best_valid : Array[CellVariant] = []
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			if grid[x][y] != null:
				continue
			
			var valid : Array[CellVariant] = get_valid_variants(x, y)
			
			if valid.is_empty():
				return {"pos": Vector2i(x, y), "valid": valid}
			
			if best_pos.x == -1 or valid.size() < best_valid.size():
				best_pos = Vector2i(x, y)
				best_valid = valid
				
				if valid.size() == 1:
					return {"pos": best_pos, "valid": best_valid}
	
	if best_pos.x == -1:
		return {}
	
	return {"pos": best_pos,"valid": best_valid}

func check_future_neighbors(pos : Vector2i) -> bool:
	for dir in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
		var next : Vector2i = pos + dir
		
		if next.x < 0 or next.x >= chunk_size:
			continue
		if next.y < 0 or next.y >= chunk_size:
			continue
		if grid[next.x][next.y] != null:
			continue
		if get_valid_variants(next.x, next.y).is_empty():
			return false
	
	return true

func shuffle_variants(list : Array[CellVariant]) -> Array[CellVariant]:
	var result : Array[CellVariant] = []
	var pool : Array[CellVariant] = list.duplicate()
	
	while not pool.is_empty():
		var chosen : CellVariant = pick_weighted(pool)
		result.append(chosen)
		pool.erase(chosen)
	
	return result

func get_valid_variants(x : int, y : int) -> Array[CellVariant]:
	var result : Array[CellVariant] = []
	
	for v in variants:
		if fits_neighbors(v, x, y):
			result.append(v)
	
	return result

func pick_weighted(list : Array[CellVariant]) -> CellVariant:
	var total_weight: float = 0.0
	
	for v in list:
		total_weight += max(v.base.weight, 0.0)
	
	if total_weight <= 0.0:
		return list[rng.randi_range(0, list.size() - 1)]
	
	var pick : float = rng.randf_range(0.0, total_weight)
	var current : float = 0.0
	
	for v in list:
		current += max(v.base.weight, 0.0)
		if pick <= current:
			return v
	
	return list[list.size() - 1]

func fits_neighbors(v : CellVariant, x : int, y : int) -> bool:
	if v.base.only_on_corner:
		if not ((x == 0 or x == chunk_size - 1) and (y == 0 or y == chunk_size - 1)):
			return false
	
	if has_cell(x - 1, y):
		var left : CellVariant = grid[x - 1][y]
		if not connection_rule.is_valid(left.E, v.W):
			return false
		if is_excluded(left, v):
			return false
	elif x == 0:
		if not connection_rule.is_valid(west_edge[y], v.W):
			return false
	
	if has_cell(x + 1, y):
		var right : CellVariant = grid[x + 1][y]
		if not connection_rule.is_valid(v.E, right.W):
			return false
		if is_excluded(v, right):
			return false
	elif x == chunk_size - 1:
		if not connection_rule.is_valid(east_edge[y], v.E):
			return false
	
	if has_cell(x, y - 1):
		var up : CellVariant = grid[x][y - 1]
		if not connection_rule.is_valid(up.S, v.N):
			return false
		if is_excluded(up, v):
			return false
	elif y == 0:
		if not connection_rule.is_valid(north_edge[x], v.N):
			return false
	
	if has_cell(x, y + 1):
		var down : CellVariant = grid[x][y + 1]
		if not connection_rule.is_valid(v.S, down.N):
			return false
		if is_excluded(v, down):
			return false
	elif y == chunk_size - 1:
		if not connection_rule.is_valid(south_edge[x], v.S):
			return false
	
	return true

func has_cell(x : int, y : int) -> bool:
	return (
		x >= 0
		and x < chunk_size
		and y >= 0
		and y < chunk_size
		and grid[x][y] != null
	)

func is_excluded(a : CellVariant, b : CellVariant) -> bool:
	for tag in a.base.exclude_tags:
		if tag in b.base.tags:
			return true
	
	for tag in b.base.exclude_tags: # might be better to remove
		if tag in a.base.tags:
			return true
	
	return false

func spawn_chunk() -> void:
	var counter : int = 0
	
	for x in range(chunk_size):
		for y in range(chunk_size):
			var v : CellVariant = grid[x][y]
			var instance : Node3D = v.base.scene.instantiate()
			
			add_child(instance)
			
			instance.position = Vector3(x * tile_size, 0, y * tile_size)
			instance.rotation_degrees.y = v.rotation * 90
			
			counter += 1
			
			if counter >= spawn_batch_size:
				counter = 0
				await get_tree().process_frame
