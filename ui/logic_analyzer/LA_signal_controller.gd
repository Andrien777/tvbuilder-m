extends HBoxContainer

class_name LASignalController

signal sig_remove_requested

var line_edit: LineEdit
var button_up: Button
var button_down: Button

func _init(
	text: String,
	height: float
):
	var label_container = HBoxContainer.new()
	var label_buttons_container = VBoxContainer.new()
	label_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	var button_up = Button.new()
	self.button_up = button_up
	button_up.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_up.svg")
	label_buttons_container.add_child(button_up)
	
	var button_down = Button.new()
	self.button_down = button_down
	button_down.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_down.svg")
	label_buttons_container.add_child(button_down)
	
	var line_edit = LineEdit.new()
	self.line_edit = line_edit
	line_edit.custom_minimum_size.y = height
	line_edit.size.y = height
	line_edit.text = text
	
	var line_edit_menu = line_edit.get_menu()
	# Remove useless menu items
	for item_index in [15,14,13,12,11,10]:
		line_edit_menu.remove_item(item_index)
	line_edit_menu.add_item("Прекратить отслеживание", 2281337)
	line_edit_menu.index_pressed.connect(
		func(index):
			if line_edit_menu.get_item_id(index) == 2281337:
				sig_remove_requested.emit()
	)
		
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_container.add_child(line_edit)
	label_container.add_child(label_buttons_container)
	add_child(label_container)
