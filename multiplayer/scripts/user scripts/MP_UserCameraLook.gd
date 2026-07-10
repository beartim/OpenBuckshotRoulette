class_name MP_UserCameraLook extends Node

@export var properties : MP_UserInstanceProperties
@export var cam_parent : Node3D
@export var cam : Camera3D
@export var cam_node : Node3D
@export var yaw_obj : Node3D
@export var controller : MP_ControllerManager
@export_range(0.0, 1.0) var sensitivity: float = 0.25
@export_range(0.0, 2.0) var sensitivity_controller: float = 0.25

var mouse_position = Vector2(0.0, 0.0)
var joystick_position = Vector2(0.0, 0.0)
var total_pitch = 0.0
var looking_active  = false
var axis_x = 0
var axis_y = 0
var x_past = false
var y_past = false

var enabled = false
var using_mouse_for_input = false

var touch_count = 0
var touch_drag_relative = Vector2.ZERO
var touch_based_free_look_active = false

func _process(_delta: float):
	if properties.is_active:
		UpdateMouseLook()
		CheckCameraReturn()
		LerpCameraReturn()
		UpdateJoystickPosition()
		CheckControllerPrompts()

func _input(event):
	if properties.is_active:
		if event.is_action_pressed("free look toggle") && !properties.is_being_revived && !properties.is_stealing_item && properties.is_allowed_to_free_look && (!properties.is_interacting_with_item or properties.is_on_jammer_selection):
			BeginCameraLook()
		if event.is_action_released("free look toggle"):
			EndCameraLook()
		
		if event is InputEventJoypadMotion:
			if event.axis == 0:
				if event.axis_value > .01 or event.axis_value < -.01:
					axis_x = event.axis_value
					x_past = true
				else:
					x_past = false
			if event.axis == 1:
				if event.axis_value > .01 or event.axis_value < -.01:
					axis_y = event.axis_value
					y_past = true
				else:
					y_past = false
		using_mouse_for_input = !(x_past or y_past)
		
		if event is InputEventMouseMotion:
			mouse_position = event.relative
		
		if event is InputEventScreenTouch:
			if event.pressed:
				touch_count += 1
			else:
				touch_count -= 1
			touch_count = maxi(touch_count, 0)
			
			if touch_count == 2 && !properties.is_being_revived && !properties.is_stealing_item && properties.is_allowed_to_free_look && (!properties.is_interacting_with_item or properties.is_on_jammer_selection):
				touch_based_free_look_active = true
				BeginCameraLook()
			elif looking_active && touch_based_free_look_active && touch_count < 2:
				EndCameraLook()
		
		if event is InputEventScreenDrag && touch_count == 2 && looking_active:
			touch_drag_relative += event.relative

func BeginCameraLook():
	controller.checkingForInput = false
	properties.intermediary.intermed_activeParent = null
	if properties.description.desc_visible:
		properties.description.EndLerp()
	mouse_position = Vector2(0, 0)
	total_pitch = 0
	StopCameraReturn()
	if !touch_based_free_look_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	looking_active = true
	fs = false

func EndCameraLook():
	looking_active = false

var fs = false
func CheckCameraReturn():
	if !looking_active && !fs:
		StartCameraReturn()
		properties.cam.returning_on_previous_lerp = false
		properties.cam.BeginLerp(properties.cam.lerp_previous, true)
		properties.cam.returning_on_previous_lerp = true
		if !touch_based_free_look_active:
			SetPreviousMouseMode()
		touch_based_free_look_active = false
		controller.checkingForInput = true
		fs = true

func SetPreviousMouseMode():
	properties.mouse_raycast.SetMouseRaycast(properties.mouse_raycast.mouse_raycast_previously_active)
	if properties.cursor.previously_visible:
		GlobalVariables.cursor_state_after_toggle = true
		properties.cursor.SetCursor(true, false)
	else:
		GlobalVariables.cursor_state_after_toggle = false
		properties.cursor.SetCursor(false, false)

func StartCameraReturn():
	elapsed = 0
	moving = true

func StopCameraReturn():
	moving = false
	elapsed = 0

func UpdateJoystickPosition():
	joystick_position = Vector2(axis_x, axis_y)

func CheckControllerPrompts():
	if looking_active:
		properties.controller_prompts_parent.modulate.a = 0
	else:
		properties.controller_prompts_parent.modulate.a = 1

var elapsed = 0
var moving = false
var dur = 2
func LerpCameraReturn():
	if moving:
		elapsed += get_process_delta_time()
		var c = clampf(elapsed / dur, 0.0, 1.0)
		c = ease(c, 0.2)
		cam.rotation_degrees = lerp(cam.rotation_degrees, Vector3(0, 0, 0), c)

func UpdateMouseLook():
	if looking_active && properties.is_active:
		var yaw
		var pitch
		if touch_based_free_look_active:
			touch_drag_relative *= sensitivity
			yaw = touch_drag_relative.x
			pitch = touch_drag_relative.y
			touch_drag_relative = Vector2.ZERO
		elif using_mouse_for_input:
			mouse_position *= sensitivity
			yaw = mouse_position.x
			pitch = mouse_position.y
			mouse_position = Vector2(0, 0)
		else:
			joystick_position *= sensitivity_controller
			yaw = joystick_position.x
			pitch = joystick_position.y
			joystick_position = Vector2(0, 0)
		
		pitch = clamp(pitch, -90 + cam_parent.rotation_degrees.x - total_pitch, 90 + cam_parent.rotation_degrees.x - total_pitch)
		total_pitch += pitch
		
		cam.rotate_object_local(Vector3(1,0,0), deg_to_rad(-pitch))
		cam_node.global_transform.basis = cam_node.global_transform.basis.rotated(Vector3.UP, deg_to_rad(-yaw))
