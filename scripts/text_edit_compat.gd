extends TextEdit
class_name TextEditCompat


func _gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_BACKSPACE:
			if has_selection():
				delete_selection()
			else:
				var line = get_caret_line()
				var col = get_caret_column()
				if col > 0:
					select(line, col - 1, line, col)
				elif line > 0:
					select(line - 1, get_line(line - 1).length(), line, col)
				delete_selection()
			accept_event()
			return

		if event.keycode == KEY_DELETE:
			if has_selection():
				delete_selection()
			else:
				var line = get_caret_line()
				var col = get_caret_column()
				var line_len = get_line(line).length()
				if col < line_len:
					select(line, col, line, col + 1)
				elif line + 1 < get_line_count():
					select(line, col, line + 1, 0)
				delete_selection()
			accept_event()
			return

		if event.keycode == KEY_LEFT and not event.ctrl_pressed:
			var line = get_caret_line()
			var col = get_caret_column()
			if col > 0:
				set_caret_column(col - 1)
			elif line > 0:
				set_caret_line(line - 1)
				set_caret_column(get_line(line - 1).length())
			accept_event()
			return

		if event.keycode == KEY_RIGHT and not event.ctrl_pressed:
			var line = get_caret_line()
			var col = get_caret_column()
			var line_len = get_line(line).length()
			if col < line_len:
				set_caret_column(col + 1)
			elif line + 1 < get_line_count():
				set_caret_line(line + 1)
				set_caret_column(0)
			accept_event()
			return

		if event.keycode == KEY_A and event.ctrl_pressed:
			select_all()
			accept_event()
			return

		if event.keycode == KEY_C and event.ctrl_pressed:
			copy()
			accept_event()
			return

		if event.keycode == KEY_V and event.ctrl_pressed:
			paste()
			accept_event()
			return
