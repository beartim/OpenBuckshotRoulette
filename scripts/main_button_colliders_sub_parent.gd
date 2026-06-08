extends Node3D

@onready var sub_nodes:Array[MeshInstance3D] = [
	$button_enter, $button_backspace, $button_a, $button_b, $button_c, $button_d, $button_e, $button_f, $button_g, $button_h, $button_i, $button_j, $button_k, $button_l, $button_m, $button_n, $button_o, $button_p, $button_q, $button_r, $button_s, $button_t, $button_u, $button_v, $button_w, $button_x, $button_y, $button_z
]

func _process(delta: float) -> void:
	if sub_nodes:
		for node:MeshInstance3D in sub_nodes:
			if node.position.y > -1.166: node.position.y = -1.166
			if node.position.y > -1.166: node.position.y = -1.166
