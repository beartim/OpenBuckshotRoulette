class_name MP_ItemResource_User extends Resource

@export var id : int
@export var name : String
@export var R_assigned_hand_path : NodePath
@export var R_assigned_mesh_path : NodePath
@export var L_assigned_hand_path : NodePath
@export var L_assigned_mesh_path : NodePath

func get_node_or_null(from: Node, path: NodePath) -> Node:
	if from == null:
		return null
	if path == NodePath():
		return null
	return from.get_node_or_null(path)
