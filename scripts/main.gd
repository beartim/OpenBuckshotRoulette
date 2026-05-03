extends Node3D
@onready var blood_splatter_plane: MeshInstance3D = $"Camera/blood splatter plane"
@onready var text_dealer: Label3D = $"ui parent_shooting decision/text dealer"
@onready var text_you: Label3D = $"ui parent_shooting decision/text you"
@onready var posterization_test: Control = $"Camera/post processing/posterization test"
@onready var viewblocker_parent: Control = $"Camera/dialogue UI/viewblocker parent"

func _ready() -> void:
	GlobalVariables.set_tree(self)
	viewblocker_parent.show()
	update_performance_options()

func _process(delta: float) -> void:
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

func update_performance_options():
	posterization_test.visible = GlobalVariables.performance_option.show_ambient_filter
