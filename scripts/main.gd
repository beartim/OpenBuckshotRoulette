extends Node3D
@onready var blood_splatter_plane: MeshInstance3D = $"Camera/blood splatter plane"
@onready var text_dealer: Label3D = $"ui parent_shooting decision/text dealer"
@onready var text_you: Label3D = $"ui parent_shooting decision/text you"
@onready var posterization_test: Control = $"Camera/post processing/posterization test"
@onready var viewblocker_parent: Control = $"Camera/dialogue UI/viewblocker parent"
@onready var brackets_tabletop: Control = $"Camera/dialogue UI/bracket ui/tabletop"
@onready var brackets_money_briefcase: Control = $"Camera/dialogue UI/bracket ui/money briefcase"
@onready var brackets_double_or_nothing_choice: Control = $"Camera/dialogue UI/bracket ui/double or nothing choice"
@onready var brackets_item_stealing: Control = $"Camera/dialogue UI/bracket ui/item stealing"
@onready var brackets_item_grabbing: Control = $"Camera/dialogue UI/bracket ui/item grabbing"
@onready var brackets_shooting_choice: Control = $"Camera/dialogue UI/bracket ui/shooting choice"
@onready var brackets_waiver_pickup: Control = $"Camera/dialogue UI/bracket ui/waiver pickup"
@onready var camera: MouseRaycast = $Camera
@onready var lp_spot_light_1: SpotLight3D = $LPSpotLight1
@onready var light_main_door_2_club_ls: OmniLight3D = $"backroom main parent/light main door2_CLUB LS"
@onready var light_main_door_club_ls: OmniLight3D = $"backroom main parent/light main door_CLUB LS"
@onready var club_light_underside_club_us: OmniLight3D = $"backroom main parent/club light underside_CLUB US"
@onready var omni_light_3d_2_ls: OmniLight3D = $"light parent/OmniLight3D2 LS"
@onready var omni_light_3d_5_ls: OmniLight3D = $"light parent/OmniLight3D5 LS"
@onready var omni_light_3d_ls: OmniLight3D = $"light parent/OmniLight3D LS"

@onready var p3should_be_hides: Array[Node3D] = [
	$"backroom visual parent/TCom_AudioEquipment0039_1_M", $"backroom visual parent/TCom_AudioEquipment0039_1_M_001", $"backroom visual parent/TCom_AudioEquipment0039_1_M_002", $"backroom visual parent/TCom_AudioEquipment0039_1_M_004",
	$"backroom visual parent/TCom_AudioEquipment0068_S",
	$"backroom visual parent/Cylinder_004", $"backroom visual parent/Cylinder_005",
	$"backroom visual parent/Cube_046",
	$"backroom visual parent/Cube_047",
	$"backroom visual parent/Plane_023", $"backroom visual parent/Plane_024",
	$"backroom visual parent/Cube_001", $"backroom visual parent/Cube_003", $"backroom visual parent/Cube_005", $"backroom visual parent/Cube_043",
	$"backroom visual parent/Cube_039",
	$restroom_CLUB/Cube_117
	
]
@onready var p2should_be_hides: Array[Node3D] = [
	$"light parent/OmniLight3D6 LS",
	$"backroom visual parent/paperwork4_001",
	$"backroom visual parent/paperwork4_009",
	$"backroom visual parent/paperwork4_003",
	$"backroom visual parent/paperwork4_002",
	$"backroom visual parent/Cube_072",
	$"backroom visual parent/Cube_073",
	$"backroom visual parent/Cylinder_006",
	$"backroom visual parent/BezierCurve_004",
	$"backroom visual parent/BezierCurve_003",
	$"backroom visual parent/boombox",
	$restroom_CLUB/BezierCurve_009,
	$"backroom visual parent/magazine2",
	$"backroom visual parent/TCom_AudioEquipment0039_1_M_002",
	$"backroom visual parent/TCom_AudioEquipment0039_1_M_001",
	$"light parent/OmniLight3D6 LS",
	$"light parent/OmniLight3D3 LS",
	$"light parent/OmniLight3D4 LS",
	$restroom_CLUB/Cube_112,
	$"restroom_CLUB/bathroom wall main_crt hole/crt main parent_002",
	$"backroom visual parent/magazine1",
	$"backroom visual parent/circuitboards_001",
	$"backroom visual parent/BezierCurve_001", $"backroom visual parent/BezierCurve_002", $"backroom visual parent/BezierCurve_003", $"backroom visual parent/BezierCurve_004", $"backroom visual parent/BezierCurve_005", $"backroom visual parent/BezierCurve_006",
	$"backroom upper cables1",
	$"backroom visual parent/TCom_AudioEquipment0064_S"
]
@onready var p1should_be_hides: Array[Node3D] = [
	$restroom_CLUB/BezierCurve_009,
	$"backroom visual parent/cup",
	$"backroom visual parent/circuitboards_007",
	$"backroom visual parent/circuitboards_017",
	$"backroom visual parent/Cylinder_003",
	$"backroom visual parent/ash tray",
	$"backroom visual parent/cigarette butts",
	$"backroom visual parent/Cylinder_032",
	$restroom_CLUB/Cube_116,
	$restroom_CLUB/Cylinder_026,
	$"backroom visual parent/Cube_006",
	$"backroom visual parent/Cube", $"backroom visual parent/Cube_002"
]

@onready var canvas_layer_back: CanvasLayer = $CanvasLayer_Back

func _ready() -> void:
	GlobalVariables.set_tree(self)
	viewblocker_parent.show()
	canvas_layer_back.hide()
	NeoSettings.connect('value_changed', update_performance_options)
	update_performance_options()

func _process(_delta: float) -> void:
	var blood_splatter_plane_alpha:= 1 - blood_splatter_plane.transparency
	if (blood_splatter_plane.material_override.albedo_color.r != blood_splatter_plane_alpha):
		blood_splatter_plane.material_override.albedo_color.r = blood_splatter_plane_alpha
		blood_splatter_plane.material_override.albedo_color.g = blood_splatter_plane_alpha
		blood_splatter_plane.material_override.albedo_color.b = blood_splatter_plane_alpha
	var text_dealer_alpha:= (1 - text_dealer.transparency)*10
	if (text_dealer.modulate.a != text_dealer_alpha):
		text_dealer.modulate.a = text_dealer_alpha
	var text_you_alpha:= (1 - text_you.transparency)*10
	if (text_you.modulate.a != text_you_alpha):
		text_you.modulate.a = text_you_alpha

func update_performance_options(_key: String = "", _value: Variant = null):
	posterization_test.visible = NeoSettings.fetch("performance/ambient_filter_enabled", true)

	var level:int = NeoSettings.fetch("performance/level", 0)
	if level >= 1:
		for node in p3should_be_hides:
			node.show()
		for node in p2should_be_hides:
			node.show()
		for node in p1should_be_hides:
			node.hide()
		lp_spot_light_1.hide()
		light_main_door_2_club_ls.shadow_enabled = false
		light_main_door_club_ls.shadow_enabled = true
		omni_light_3d_2_ls.shadow_enabled = true
		omni_light_3d_5_ls.shadow_enabled = true
		omni_light_3d_ls.shadow_enabled = true
		camera.far = 280
	if level >= 2:
		for node in p3should_be_hides:
			node.show()
		for node in p2should_be_hides:
			node.hide()
		light_main_door_2_club_ls.hide()
		camera.far = 200
		lp_spot_light_1.show()
		light_main_door_club_ls.shadow_enabled = false
		omni_light_3d_2_ls.shadow_enabled = false
		omni_light_3d_5_ls.shadow_enabled = false
		omni_light_3d_ls.shadow_enabled = false
	if level >= 3:
		for node in p3should_be_hides:
			node.hide()
		club_light_underside_club_us.omni_range = 120
		club_light_underside_club_us.shadow_enabled = true
	else:
		club_light_underside_club_us.omni_range = 186.24
		club_light_underside_club_us.shadow_enabled = true
	if level <= 0:
		for node in p2should_be_hides:
			node.show()
		for node in p1should_be_hides:
			node.show()
		for node in p3should_be_hides:
			node.show()
		camera.far = 2000
		lp_spot_light_1.hide()
		light_main_door_2_club_ls.shadow_enabled = true
		light_main_door_club_ls.shadow_enabled = true

var last_back_preessed_time := 0

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed('back') && Time.get_ticks_msec() - last_back_preessed_time >= 33.33:
		canvas_layer_back.visible = !canvas_layer_back.visible
	last_back_preessed_time = Time.get_ticks_msec()


func _on_true_button_back_yes_pressed() -> void:
	GlobalVariables.tree.change_scene_to_file("res://scenes/menu.tscn")


func _on_true_button_back_no_pressed() -> void:
	canvas_layer_back.visible = false
