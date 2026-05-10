class_name MouseRaycast extends Camera3D

@export var checkingOverride : bool
@export var cursor : CursorManager
var mouse = Vector2()
var result = null

var controller_overriding = false

func _input(event):
	if event is InputEventMouse:
		if(!controller_overriding): mouse = event.position

func _process(_delta: float):
	get_selection()

func get_selection():
	var worldspace = get_world_3d().direct_space_state
	var start = project_ray_origin(mouse)
	var end = project_position(mouse, 20000)
	result = worldspace.intersect_ray(PhysicsRayQueryParameters3D.create(start, end))

func GetRaycastOverride(pos_override : Vector2):
	controller_overriding = true
	mouse = pos_override

func StopRaycastOverride():
	controller_overriding = false

func force_raycast_update():
	var space_state = get_world_3d().direct_space_state
	var mouse_pos = get_viewport().get_mouse_position()
	var camera = get_viewport().get_camera_3d()
	var origin = camera.project_ray_origin(mouse_pos)
	var end = origin + camera.project_ray_normal(mouse_pos) * 1000
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	result = space_state.intersect_ray(query)

func get_collider_result():
	return result
