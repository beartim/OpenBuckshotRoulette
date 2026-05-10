extends Node3D

func _ready() -> void:
	$"user ui/posterization".visible = NeoSettings.fetch('performance/ambient_filter_enabled', true)
