extends Node3D
@onready var viewblocker_parent: Control = $"Camera/dialogue UI/viewblocker parent"
@onready var posterization_test: Control = $"Camera/post processing/posterization test"
@onready var sub_options_select: Control = $"Camera/dialogue UI/menu ui/sub options select"

func _ready() -> void:
	GlobalVariables.set_tree(self)
	viewblocker_parent.show()
	sub_options_select.hide()
	update_performance_options()

func update_performance_options():
	posterization_test.visible = GlobalVariables.performance_option.show_ambient_filter
