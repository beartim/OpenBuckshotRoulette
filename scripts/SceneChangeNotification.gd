extends Node

func _ready():
	if (GlobalVariables.tree.current_scene):
		print("user entered scene: ", GlobalVariables.tree.current_scene.name)
