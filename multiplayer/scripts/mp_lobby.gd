extends Node3D
@onready var vhs_bleed: CanvasLayer = $"ui/vhs bleed"
@onready var vhs_grain: CanvasLayer = $"ui/vhs grain"
@onready var viewblocker_join_from_search_result: ColorRect = $"ui/viewblocker_join from search result"
@onready var viewblocker: ColorRect = $ui/viewblocker
@onready var posterization: Control = $"post processing/posterization"
@onready var ui_parent_lobby_home: Control = $"ui/ui parent main/ui parent_lobby home"
@onready var ui_parent_match_customization: Control = $"ui/ui parent main/ui parent_match customization"
@onready var ui_parent_lobby_search: Control = $"ui/ui parent main/ui parent_lobby search"

func _ready() -> void:
	vhs_bleed.show()
	vhs_grain.show()
	viewblocker_join_from_search_result.show()
	viewblocker.show()
	ui_parent_lobby_home.show()
	ui_parent_match_customization.hide()
	ui_parent_lobby_search.hide()
	NeoSettings.fetch("performance/ambient_filter_enabled", true)
	_update_performance_options()

func _update_performance_options(_key: String = "", _value: Variant = null) -> void:
	posterization.visible = NeoSettings.fetch("performance/ambient_filter_enabled", true)
