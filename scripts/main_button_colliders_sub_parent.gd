extends Node3D

@onready var button_enter: MeshInstance3D = $button_enter
@onready var interaction_branch_enter: InteractionBranch = $"button_enter/interaction branch_enter"
@onready var sub_nodes: Array[MeshInstance3D] = [
	button_enter, $button_backspace, $button_a, $button_b, $button_c, $button_d, $button_e, $button_f, $button_g, $button_h, $button_i, $button_j, $button_k, $button_l, $button_m, $button_n, $button_o, $button_p, $button_q, $button_r, $button_s, $button_t, $button_u, $button_v, $button_w, $button_x, $button_y, $button_z
]

@export var interaction_manager: InteractionManager

const keys26 = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z']
const keysSpecial = ['enter', 'backspace']

func _process(_delta: float) -> void:
	if sub_nodes:
		for node: MeshInstance3D in sub_nodes:
			if node.position.y > -1.166: node.position.y = -1.166
			if node.position.y > -1.166: node.position.y = -1.166
func _input(event: InputEvent) -> void:
	if !interaction_branch_enter.interactionAllowed || interaction_manager.sign.input_finished || !(event is InputEventKey) || !event.is_pressed() || event.is_echo(): return
	var mKey = event.as_text_keycode().to_lower()
	if keys26.has(mKey):
		interaction_manager.sign.GetInput(mKey, '')
		var node = sub_nodes[keys26.find(mKey) + 2]
		if node:
			node = node.get_node('signature button branch')
		if node: node.Press()
	elif keysSpecial.has(mKey):
		interaction_manager.sign.GetInput('', mKey)
		var node = sub_nodes[keysSpecial.find(mKey)]
		if node:
			node = node.get_node('signature button branch')
		if node: node.Press()
