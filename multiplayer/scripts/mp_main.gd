extends Node3D
@onready var viewblocker_global: Control = $"main ui/viewblocker global"
@onready var input_blocker: Control = $"main ui/input blocker"
@onready var some_dancers: Array[Node3D] = [
	$"dancers parent/dancer export1",
	$"dancers parent/dancer export3",
	$"dancers parent/dancer export5",
	$"dancers parent/dancer export7",
	$"dancers parent/dancer export9",
	$"dancers parent/dancer export11",
	$"dancers parent/dancer export13",
	$"dancers parent/dancer export15",
	$"dancers parent/dancer export19",
	$"dancers parent/dancer export21",
	$"dancers parent/dancer export17",
]
@onready var global_camera: Camera3D = $"global camera"
@onready var light_center: OmniLight3D = $"light parent/light_center"
@onready var p1should_be_hides: Array[Node3D] = [
	$"interior environment main1/interior environment parent/pipes",
	$"interior environment main1/interior environment parent/radiators",
	$"exterior environment main/exterior environment parent/environment backdrop",
	$"light parent/light_interior club upper light hit1",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_013",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage2",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_012",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/food can_003",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/boombox",
	$"interior environment main1/interior environment parent/props power supply",
	$"interior environment main1/interior environment parent/plastic crate",
	$"interior environment main1/interior environment parent/cloth prop",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/food can_013",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/food can_012",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/food can_011",
	$"interior environment main1/interior environment parent/fan parent",
	$"interior environment main1/interior environment parent/device voltmeter",
	$"interior environment main1/interior environment parent/food can_001",
	$"interior environment main1/interior environment parent/food can_002",
	$"interior environment main1/interior environment parent/food can",
	$"interior environment main1/interior environment parent/fan parent2",
	$"interior environment main1/interior environment parent/wood pallet",
	$"interior environment main1/interior environment parent/pen"
]
@onready var p2should_be_hides: Array[Node3D] = [
	$"interior environment main1/interior environment parent/estonia speaker",
	$"interior environment main1/interior environment parent/cloth prop",
	$"interior environment main1/interior environment parent/wall shelf",
	$"interior environment main1/interior environment parent/buckets",
	$"interior environment main1/interior environment parent/sponge",
	$"dancers parent",
	$"interior environment main1/interior environment parent/wooden pallet",
	$"interior environment main1/interior environment parent/device audio",
	$"interior environment main1/interior environment parent/subwoofer",
	$"light parent/light_test2",
	$"light parent/light_test",
	$"light parent/light_test3",
	$"light parent/light_test4",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/pickup truck",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_001",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_004", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_005", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_006", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_007", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_008", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_009", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_010", $"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_011",

]

@onready var p3should_be_hides: Array[Node3D] = [
	$"interior environment main1/interior environment parent/theater light top parent",
	$"interior environment main1/interior environment parent/theater light top parent_001",
	$"interior environment main1/interior environment parent/power supply cart",
	$"interior environment main1/interior environment parent/wires",
	$"interior environment main1/interior environment parent/chair",
	$"interior environment main1/interior environment parent/speaker tall",
	$"interior environment main1/interior environment parent/plastic crate", $"interior environment main1/interior environment parent/plastic crate_001", $"interior environment main1/interior environment parent/plastic crate_002",
	$"interior environment main1/interior environment parent/subwoofer_001",
	$"interior environment main1/interior environment parent/stool",
	$"interior environment main1/interior environment parent/device combinator",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_002",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/exterior foliage_003",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/trash container",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/wood pallet_001", $"exterior environment main/exterior environment parent/exterior environment prop parent/wood pallet_002", $"exterior environment main/exterior environment parent/exterior environment prop parent/wood pallet_003", $"exterior environment main/exterior environment parent/exterior environment prop parent/wood pallet_004",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/van",
	$"exterior environment main/exterior environment parent/hustler_armature/Skeleton3D",
	$"interior environment main1/interior environment parent/wire ties",
	$"light parent/light_interior club upper light hit1",
	$"light parent/light_interior club upper light hit2",
	$"exterior environment main/exterior environment parent/exterior environment prop parent/wood pallet_005"
]
@onready var canvas_layer_back: CanvasLayer = $CanvasLayer_Back

func _ready() -> void:
	viewblocker_global.show()
	input_blocker.show()
	canvas_layer_back.hide()
	NeoSettings.value_changed.connect(_update_performance_options)
	_update_performance_options()

func _update_performance_options(_key: String = "", _value: Variant = null) -> void:
	if $"user instance_main1/user ui/posterization":
		$"user instance_main1/user ui/posterization".visible = false
	var level:int = NeoSettings.fetch("performance/level", 0)
	if level >= 1:
		for node in p3should_be_hides:
			node.show()
		for node in p2should_be_hides:
			node.show()
		for node in p1should_be_hides:
			node.hide()
		for dancer in some_dancers:
			dancer.hide()
		
		light_center.omni_attenuation = 1
		light_center.shadow_opacity = 1
		global_camera.far = 800
	if level >= 2:
		for node in p2should_be_hides:
			node.hide()
		for node in p3should_be_hides:
			node.show()
		global_camera.far = 500
		light_center.omni_attenuation = 0.6
		light_center.shadow_opacity = 0.65
	if level >= 3:
		for node in p3should_be_hides:
			node.hide()
		global_camera.far = 384
	if level <= 0:
		for dancer in some_dancers:
			dancer.show()
		global_camera.far = 4000
		light_center.omni_attenuation = 1
		light_center.shadow_opacity = 1
		for node in p3should_be_hides:
			node.show()
		for node in p2should_be_hides:
			node.show()
		for node in p1should_be_hides:
			node.show()

var last_back_preessed_time := 0

func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed('back') && Time.get_ticks_msec() - last_back_preessed_time >= 33.33:
		if viewblocker_global.visible == false:
			canvas_layer_back.hide()
			return
		canvas_layer_back.visible = !canvas_layer_back.visible
	last_back_preessed_time = Time.get_ticks_msec()


func _on_true_button_back_yes_pressed() -> void:
	GlobalVariables.tree.change_scene_to_file("res://scenes/menu.tscn")


func _on_true_button_back_no_pressed() -> void:
	canvas_layer_back.visible = false
