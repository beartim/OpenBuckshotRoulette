extends Node
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var label_bullets_count: Label = $CanvasLayer/Control/Panel_Gambling/Label_BulletsCount
@onready var label_next_bullet: Label = $CanvasLayer/Control/Panel_Gambling/Label_NextBullet
@onready var label_game_speed: Label = $CanvasLayer/Control/Panel_System/HSlider_GameSpeed/Label_GameSpeed
@onready var label_player_health: Label = $CanvasLayer/Control/Panel_Gambling/Label_PlayerHealth
@onready var label_dealer_health: Label = $CanvasLayer/Control/Panel_Gambling/Label_DealerHealth

var _forcing_mouse_mode := false
var _forced_mouse_mode := Input.MOUSE_MODE_VISIBLE
var _mouse_mode_to_restore := Input.MOUSE_MODE_VISIBLE

var lives := 0
var blanks := 0
var next_bullet := false
var has_next_bullet := false
var player_health:= 0
var dealer_health:= 0

## Multiplayer: hide dealer HP in tools and read shells from MAIN_active_sequence_dict instead of ShellSpawner
var _mp_hide_dealer_in_debug_panel := false
var mp_gambling_refresh_ttl := 0.0

func  _ready() -> void:
	add_to_group("debug_tools")
	canvas_layer.hide()
	set_process(false)

func _input(event: InputEvent) -> void:
	if (Input.is_action_just_pressed("debug_tools")):
		_set_debug_visible(!canvas_layer.visible)

func _process(delta: float) -> void:
	if !_forcing_mouse_mode:
		return
	var gs_mp: MP_GameStateManager = _find_mp_game_state()
	if gs_mp != null:
		mp_gambling_refresh_ttl -= delta
		if mp_gambling_refresh_ttl <= 0.0:
			mp_gambling_refresh_ttl = 0.12
			_refresh_mp_gambling_from_game_state(gs_mp)
	var current_mode := Input.get_mouse_mode()
	if current_mode != _forced_mouse_mode:
		_mouse_mode_to_restore = current_mode
		Input.set_mouse_mode(_forced_mouse_mode)

func _exit_tree() -> void:
	_end_forcing_mouse_mode()

func _set_debug_visible(visible: bool) -> void:
	canvas_layer.visible = visible
	if visible:
		_begin_forcing_mouse_mode()
		var gs: MP_GameStateManager = _find_mp_game_state()
		if gs != null:
			mp_gambling_refresh_ttl = 0.0
			_refresh_mp_gambling_from_game_state(gs)
		else:
			update_gambling_status()
	else:
		_mp_hide_dealer_in_debug_panel = false
		_end_forcing_mouse_mode()

func _begin_forcing_mouse_mode() -> void:
	if _forcing_mouse_mode:
		return
	_forcing_mouse_mode = true
	_mouse_mode_to_restore = Input.get_mouse_mode()
	Input.set_mouse_mode(_forced_mouse_mode)
	set_process(true)

func _end_forcing_mouse_mode() -> void:
	if !_forcing_mouse_mode:
		return
	_forcing_mouse_mode = false
	set_process(false)
	Input.set_mouse_mode(_mouse_mode_to_restore)

func _on_h_slider_game_speed_value_changed(value: float) -> void:
	label_game_speed.text = 'GameSpeed: ' + str(value)
	GlobalVariables.SetDebugTimeScaleMultiplier(value)

func set_number_of_lives(num: int):
	lives = num
	
func set_number_of_blanks(num: int):
	blanks = num

func set_next_bullet(is_live):
	next_bullet = is_live

func _apply_sequence_summary(sequence: Array[String]) -> void:
	lives = sequence.count("live")
	blanks = sequence.count("blank")
	has_next_bullet = sequence.size() > 0
	if has_next_bullet:
		next_bullet = sequence[0] == "live"


func sync_from_sequence(sequence: Array[String]) -> void:
	_apply_sequence_summary(sequence)
	update_gambling_status()


func sync_health(player: int, dealer: int) -> void:
	_mp_hide_dealer_in_debug_panel = false
	player_health = player
	dealer_health = dealer
	if canvas_layer.visible:
		update_gambling_status()

func update_gambling_status():
	label_bullets_count.text = 'Lives: ' + str(lives) + ' Blanks: ' + str(blanks)
	if !has_next_bullet:
		label_next_bullet.text = 'Next: -'
		label_next_bullet.label_settings.font_color = Color.hex(0xffffffff)
	else:
		if (next_bullet):
			label_next_bullet.text = 'Next: Live'
			label_next_bullet.label_settings.font_color = Color.hex(0xdb4449ff)
		else:
			label_next_bullet.text = 'Next: Blank'
			label_next_bullet.label_settings.font_color = Color.hex(0x00ababff)
	
	label_player_health.text = 'PHealth: ' + str(player_health)
	if _mp_hide_dealer_in_debug_panel:
		label_dealer_health.text = 'DHealth: —'
	else:
		label_dealer_health.text = 'DHealth: ' + str(dealer_health)


func _on_button_add_dealer_health_pressed() -> void:
	_adjust_health(false, 1)


func _on_button_reduce_dealer_health_pressed() -> void:
	_adjust_health(false, -1)


func _on_button_add_player_health_pressed() -> void:
	_adjust_health(true, 1)


func _on_button_reduce_player_health_2_pressed() -> void:
	_adjust_health(true, -1)

func _adjust_health(is_player: bool, delta: int) -> void:
	var gs_mp: MP_GameStateManager = _find_mp_game_state()
	if gs_mp != null:
		if is_player:
			_adjust_mp_local_player_health(gs_mp, delta)
		_refresh_mp_gambling_from_game_state(gs_mp)
		return
	
	var rm = get_tree().get_first_node_in_group("round_manager")
	if rm == null:
		return
	var max_health := _get_round_max_health(rm)
	if is_player:
		var v: int = rm.health_player + delta
		v = maxi(v, 0)
		if max_health > 0:
			v = mini(v, max_health)
		rm.health_player = v
	else:
		var v: int = rm.health_opponent + delta
		v = maxi(v, 0)
		if max_health > 0:
			v = mini(v, max_health)
		rm.health_opponent = v
	if rm.healthCounter != null:
		rm.healthCounter.UpdateDisplay()
	rm.CheckIfOutOfHealth()
	sync_health(rm.health_player, rm.health_opponent)

func _get_round_max_health(rm) -> int:
	if rm.roundArray == null:
		return 0
	var idx: int = rm.currentRound
	if idx < 0 or idx >= rm.roundArray.size():
		return 0
	return int(rm.roundArray[idx].startingHealth)


func _find_mp_game_state() -> MP_GameStateManager:
	return _find_mp_game_state_under(get_tree().root)


func _find_mp_game_state_under(node: Node) -> MP_GameStateManager:
	if node is MP_GameStateManager:
		return node as MP_GameStateManager
	for child in node.get_children():
		var found: MP_GameStateManager = _find_mp_game_state_under(child)
		if found != null:
			return found
	return null


func _coerce_shell_strings(seq: Variant) -> Array[String]:
	var out: Array[String] = []
	if seq is Array:
		for elem in seq as Array:
			out.append(str(elem))
	return out


func _refresh_mp_gambling_from_game_state(gs: MP_GameStateManager) -> void:
	_mp_hide_dealer_in_debug_panel = true
	var d: Variant = gs.MAIN_active_sequence_dict
	if d is Dictionary && not (d as Dictionary).is_empty() && (d as Dictionary).has("sequence_in_shotgun"):
		_apply_sequence_summary(_coerce_shell_strings((d as Dictionary)["sequence_in_shotgun"]))
	else:
		lives = 0
		blanks = 0
		has_next_bullet = false
	
	if gs.instance_handler != null:
		for prop in gs.instance_handler.instance_property_array:
			if prop.user_id == GlobalSteam.STEAM_ID:
				player_health = prop.health_current
				break
	
	update_gambling_status()


func _adjust_mp_local_player_health(gs: MP_GameStateManager, delta: int) -> void:
	var rd: Variant = gs.MAIN_active_round_dict
	if gs.instance_handler == null:
		return
	for prop in gs.instance_handler.instance_property_array:
		if prop.user_id != GlobalSteam.STEAM_ID:
			continue
		var mx: int = prop.health_on_round_start
		if rd is Dictionary:
			mx = int((rd as Dictionary).get("starting_health", mx))
		if mx <= 0:
			mx = prop.health_current
		var nv: int = prop.health_current + delta
		nv = maxi(nv, 0)
		nv = mini(nv, maxi(mx, 1))
		prop.health_current = nv
		if prop.health_counter != null:
			prop.health_counter.UpdateDisplay()
		break
