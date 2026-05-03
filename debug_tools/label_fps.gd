extends Label

var frames_render: int = 0
var frames_render_2: float = 0.0
var frames_physics: int = 0
var frames_physics_2: float = 0.0

func _physics_process(delta: float) -> void:
	frames_physics += 1
	frames_physics_2 = 1.0 / delta
	
func _process(delta: float) -> void:
	frames_render += 1
	frames_render_2 = 1.0 / delta

func _on_timer_fps_timeout() -> void:
	text = 'FPS: ' + str(frames_render) + 'r ' + str(frames_physics) + 'p\n     ' + str("%.2f" % frames_render_2) + 'r ' + str("%.2f" % frames_physics_2) + 'p'
	frames_physics = 0
	frames_render = 0
