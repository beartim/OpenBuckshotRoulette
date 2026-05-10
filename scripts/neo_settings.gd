extends Node

signal value_changed(key: String, value: Variant)

const _PATH: String = "user://buckshot_neo_settings.shell"
var settings: Dictionary = {
	performance = {
		max_fps = 120,
		level = 0,
		ambient_filter_enabled = true
	}
}


func _ready() -> void:
	_read()
	_emit_all_settings(settings, "")
	print('NeoSettings loaded')

func fetch(key: String, default: Variant = null) -> Variant:
	var keys = _split_key(key)
	var current = settings
	
	for i in range(keys.size()):
		var k = keys[i]
		if current is Dictionary and k in current:
			if i == keys.size() - 1:
				return current[k]
			current = current[k]
		else:
			return default
	return default

func put(key: String, value: Variant) -> void:
	var keys = _split_key(key)
	var current = settings
	
	for i in range(keys.size() - 1):
		var k = keys[i]
		if not k in current or not (current[k] is Dictionary):
			current[k] = {}
		current = current[k]
	
	current[keys[-1]] = value
	value_changed.emit(key, value)
	_save()

func _split_key(key: String) -> PackedStringArray:
	var expression = RegEx.new()
	expression.compile("[./\\\\]")
	return expression.sub(key, "|", true).split("|", false)

func _save() -> void:
	var file = FileAccess.open(_PATH, FileAccess.WRITE)
	if file:
		file.store_var(settings)

func _read() -> void:
	if FileAccess.file_exists(_PATH):
		var file = FileAccess.open(_PATH, FileAccess.READ)
		if file:
			var data = file.get_var()
			if data is Dictionary:
				settings = data
				return
			else:
				settings = {}
	_save()

func _emit_all_settings(dict: Dictionary, prefix: String) -> void:
	for key in dict:
		var full_key = key if prefix == "" else prefix + "." + key
		var value = dict[key]
		if value is Dictionary:
			_emit_all_settings(value, full_key)
		else:
			value_changed.emit(full_key, value)
