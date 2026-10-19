class_name Cell
extends Resource
## This class is used to create cells for WFC to use

## Scene of the cell
@export var scene : PackedScene = null

## Weight of the cell
@export var weight : float = 1.0

## Tags of the cell
@export var tags : Array[String] = []

## Has rotated variants
@export var can_rotate : bool = false

@export_group("Conections")

## Conection in Z- direction
@export var N : int = 0
## Conection in X+ direction
@export var E : int = 0
## Conection in Z+ direction
@export var S : int = 0
## Conection in X- direction
@export var W : int = 0 

@export var only_on_corner : bool = false

## What naighbour tags are not allowed
@export var exclude_tags : Array[String] = []
