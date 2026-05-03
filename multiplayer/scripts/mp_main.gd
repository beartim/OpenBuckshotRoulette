extends Node3D
@onready var viewblocker_global: Control = $"main ui/viewblocker global"
@onready var input_blocker: Control = $"main ui/input blocker"

func _ready() -> void:
	viewblocker_global.show()
	input_blocker.show()
