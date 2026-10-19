class_name ConnectionRule
extends Resource
## This class is used to create connection rules for WFC to use

## Array of allowed connection pairs
@export var allowed_pairs : Array[Vector2i] = []

var allowed_lookup : Dictionary = {}

func build_lookup() -> void:
	allowed_lookup.clear()
	
	for pair in allowed_pairs:
		allowed_lookup[pair] = true
		allowed_lookup[Vector2i(pair.y, pair.x)] = true

## Determines if connection is allowed
func is_valid(a: int, b: int) -> bool:
	return allowed_lookup.has(Vector2i(a, b))
