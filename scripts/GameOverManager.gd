class_name GameOverManager extends Node

func PlayerWon():
	GlobalVariables.tree.change_scene_to_file("res://scenes/win.tscn")
