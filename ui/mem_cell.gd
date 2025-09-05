extends Label
class_name MemCell

var content_int = -1
var stylebox_selected: StyleBoxFlat
var stylebox_weakly_selected: StyleBoxFlat
var stylebox_bold_selected:StyleBoxFlat
var stylebox_normal: StyleBoxFlat
signal mouse_enter
signal mouse_exit
var addr = -1
var is_4bit = false
signal content_changed(addr, value)
var font = preload("res://ui/JetBrainsMonoNL-Regular.ttf")
var edit: LineEdit
var regex = RegEx.new()

var content:
	get: return content_int
	set (value):
		content_int = value
		if value == -1:
			text = "??"
		else:
			text = "%02x" % content_int

func _ready() -> void:
	text = "??"
	stylebox_normal = StyleBoxFlat.new()
	stylebox_normal.bg_color = Color("4d4d4d")
	stylebox_selected = StyleBoxFlat.new()
	stylebox_selected.bg_color = Color("000000")
	stylebox_weakly_selected = StyleBoxFlat.new()
	stylebox_weakly_selected.bg_color = Color("3d3d3d")
	stylebox_bold_selected = StyleBoxFlat.new()
	stylebox_bold_selected.bg_color = Color.ORANGE_RED
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_theme_font_override("font", font)
	regex.compile("^[0-9A-Fa-f]{0,2}$")
	
func _on_mouse_entered():
	if not is_selected():
		add_theme_stylebox_override("normal", stylebox_selected)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		if not is_selected():
			add_theme_stylebox_override("normal", stylebox_bold_selected)
		else:
			add_theme_stylebox_override("normal", stylebox_weakly_selected)
	mouse_enter.emit()

func _on_mouse_exited():
	if not is_selected():
		reset_select()
	mouse_exit.emit()

func set_weak_select():
	if not is_selected():
		add_theme_stylebox_override("normal", stylebox_weakly_selected)

func reset_select():
	add_theme_stylebox_override("normal", stylebox_normal)

func is_selected():
	return get_theme_stylebox("normal")==stylebox_bold_selected

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if not is_selected():
			add_theme_stylebox_override("normal", stylebox_bold_selected)
		else:
			add_theme_stylebox_override("normal", stylebox_weakly_selected)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		edit = LineEdit.new()
		add_child(edit)
		edit.text_submitted.connect(change_value)
		edit.text_changed.connect(validate_edit_text)
		edit.position = Vector2(-2, -5)
		edit.flat = true
		if is_4bit:
			edit.text = text[1]
			edit.max_length = 1
		else:
			edit.text = text
			edit.max_length = 2
		edit.grab_focus()
		edit.focus_exited.connect(_on_edit_focus_lost)
		edit.add_theme_stylebox_override("normal", stylebox_normal)
		edit.add_theme_stylebox_override("focus", stylebox_normal)

func change_value(text):
	content = (text as String).hex_to_int()
	content_changed.emit(addr, content)
	edit.queue_free()

func _on_edit_focus_lost():
	change_value(edit.text)


func validate_edit_text(text):
	var valid_substr = regex.search(text)
	if not valid_substr:
		edit.text = self.text
		return
