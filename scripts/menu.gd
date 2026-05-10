extends Node3D
@onready var viewblocker_parent: Control = $"Camera/dialogue UI/viewblocker parent"
@onready var posterization_test: Control = $"Camera/post processing/posterization test"
@onready var sub_options_select: Control = $"Camera/dialogue UI/menu ui/sub options select"
@onready var main_screen: Control = $"Camera/dialogue UI/menu ui/main screen"
@onready var options_audio_video: Control = $"Camera/dialogue UI/menu ui/options_audio video"
@onready var options_controller: Control = $"Camera/dialogue UI/menu ui/options_controller"
@onready var credits: Control = $"Camera/dialogue UI/menu ui/credits"
@onready var language: Control = $"Camera/dialogue UI/menu ui/language"
@onready var controller_rebinding: Control = $"Camera/dialogue UI/menu ui/controller rebinding"
@onready var mouse_blocker: Control = $"Camera/dialogue UI/menu ui/mouse blocker"
@onready var control_main_options: Control = $"Camera/dialogue UI/menu ui/main screen/Control_MainOptions"
@onready var options_online_service: Control = $"Camera/dialogue UI/menu ui/options_online service"
@onready var button_class_pause_server_address: ButtonClass = $"Camera/dialogue UI/menu ui/options_online service/Control/Label/Label_ServerAddress/Label/true button/button class_pause server address"
@onready var options_manager: OptionsManager = $"standalone managers/options manager"
@onready var label_server_address: Label = $"Camera/dialogue UI/menu ui/options_online service/Control/Label/Label_ServerAddress"
@onready var button_class_reconnect_to_ws: ButtonClass = $"Camera/dialogue UI/menu ui/options_online service/Control/Label2/Label_ConnectionStatus/Label/true button/button class_reconnect_to_ws"
@onready var label_connection_status: Label = $"Camera/dialogue UI/menu ui/options_online service/Control/Label2/Label_ConnectionStatus"

func _ready() -> void:
	GlobalVariables.set_tree(self )
	viewblocker_parent.show()
	control_main_options.show()
	sub_options_select.hide()
	main_screen.show()
	options_audio_video.hide()
	options_controller.hide()
	options_online_service.hide()
	credits.hide()
	language.hide()
	bind_events()
	if DebugTools.DEBUG_TOOLS_ENABLED && DebugTools.SKIP_SPLASH_ANIM:
		viewblocker_parent.hide()
		mouse_blocker.hide()
		$"standalone managers/cursor manager".SetCursor(true, false)
	NeoSettings.connect('value_changed', update_performance_options)
	update_performance_options()

func bind_events():
	button_class_pause_server_address.connect("is_pressed", _on_button_class_pause_server_address_is_pressed)
	button_class_reconnect_to_ws.connect('is_pressed', _on_button_class_reconnect_to_ws_is_pressed)

func update_performance_options(_key: String = "", _value: Variant = null):
	posterization_test.visible = NeoSettings.fetch("performance/ambient_filter_enabled", true)

func get_server_address_from_clipboard() -> String:
	var text = DisplayServer.clipboard_get()
	return text.strip_edges()

func is_valid_ws_url(url: String) -> bool:
	var lower = url.to_lower()
	
	if not (lower.begins_with("ws://") or lower.begins_with("wss://")):
		return false
	if not (url.contains(".") and url.count(":") >= 2):
		return false
	
	var address_part = url.split("//")[1]
	if address_part.ends_with(":") or " " in address_part:
		return false
	var parts = address_part.split(":")
	if parts.size() > 1:
		var port_str = parts[-1].split("/")[0]
		if not port_str.is_valid_int():
			return false
			
	return true

func _on_button_class_pause_server_address_is_pressed():
	var text = get_server_address_from_clipboard()
	if is_valid_ws_url(text):
		options_manager.setting_server_address = text
		options_manager.SaveSettings()
		update_server_address_label()

func update_server_address_label():
	label_server_address.text = Steam.server_address

func _on_button_class_reconnect_to_ws_is_pressed():
	GlobalSteam.connect_to_server()

func _process(_delta: float) -> void:
	if options_online_service.visible:
		var state = GlobalSteam.ws_peer.get_ready_state()
		
		if state == WebSocketPeer.STATE_OPEN:
			label_connection_status.text = 'CONNECTED'
		elif state == WebSocketPeer.STATE_CONNECTING:
			label_connection_status.text = 'CONNECTING'
		else:
			label_connection_status.text = 'DISCONNECTED'
