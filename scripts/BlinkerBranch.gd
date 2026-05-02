class_name BlinkerBranch extends Node

@export var mat_1 : StandardMaterial3D
@export var mat_2 : StandardMaterial3D
@export var delay_range1 : float
@export var delay_range2 : float
var parent : MeshInstance3D
var looping = false

func _ready():
	parent = get_parent() as MeshInstance3D
	if parent == null:
		return
	looping = true
	call_deferred("Loop")

func Loop():
	while looping and is_inside_tree() and is_instance_valid(parent):
		var tree := get_tree()
		if tree == null:
			return
		var delay := randf_range(delay_range1, delay_range2)
		parent.set_surface_override_material(0, mat_1)
		await tree.create_timer(delay, false).timeout
		if !looping or !is_inside_tree() or !is_instance_valid(parent):
			return
		tree = get_tree()
		if tree == null:
			return
		parent.set_surface_override_material(0, mat_2)
		await tree.create_timer(delay, false).timeout

func _exit_tree() -> void:
	looping = false
