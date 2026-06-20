class_name CursorManager extends Node

@export var speaker : AudioStreamPlayer2D
@export var cursor_point : CompressedTexture2D
@export var cursor_hover : CompressedTexture2D
@export var cursor_invalid : CompressedTexture2D
var cursor_visible = false
var controller_active = false

func _ready():
	SetCursor(false, false)

func SetCursor(isVisible : bool, playSound : bool):
	if (playSound): speaker.play()
	if (isVisible):
		if (!controller_active): Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else: Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		cursor_visible = true
	if (!isVisible):
		Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
		cursor_visible = false

func SetCursorImage(alias : String):
	match(alias):
		"hover": Input.set_custom_mouse_cursor(cursor_hover, Input.CursorShape.CURSOR_ARROW, Vector2(9, 0))
		"point": Input.set_custom_mouse_cursor(cursor_point, Input.CursorShape.CURSOR_ARROW, Vector2(12, 0))
		"invalid": Input.set_custom_mouse_cursor(cursor_invalid, Input.CursorShape.CURSOR_ARROW, Vector2(12, 0))
	pass
