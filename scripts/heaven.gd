extends Node3D
@onready var viewblocker_parent: Control = $"Camera/dialogue UI/viewblocker parent"

func _ready() -> void:
	GlobalVariables.set_tree(self)
	viewblocker_parent.show()
