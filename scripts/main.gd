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
	$restroom_CLUB/Cube_112
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
	$restroom_CLUB/Cylinder_026
]

func _ready() -> void:
	GlobalVariables.set_tree(self)
	viewblocker_parent.show()
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
		for node in p2should_be_hides:
			node.show()
		for node in p1should_be_hides:
			node.hide()
		lp_spot_light_1.hide()
		camera.far = 280
	if level >= 2:
		for node in p1should_be_hides:
			node.hide()
		for node in p2should_be_hides:
			node.hide()
		camera.far = 200
		lp_spot_light_1.show()
	if level <= 0:
		for node in p2should_be_hides:
			node.show()
		for node in p1should_be_hides:
			node.show()
		camera.far = 2000
		lp_spot_light_1.hide()
