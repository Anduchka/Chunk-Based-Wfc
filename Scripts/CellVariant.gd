class_name CellVariant

var base : Cell
var rotation : int = 0

var N : int
var E : int
var S : int
var W : int

func _init(cell : Cell, rot : int) -> void:
	base = cell
	rotation = rot
	apply_rotation()

func apply_rotation() -> void:
	var n : int = base.N
	var e : int = base.E
	var s : int = base.S
	var w : int = base.W
	
	match rotation:
		0:
			N = n; E = e; S = s; W = w
		1:
			N = e; E = s; S = w; W = n
		2:
			N = s; E = w; S = n; W = e
		3:
			N = w; E = n; S = e; W = s
