extends HBoxContainer

class_name LASignalGroupController

const Radix = preload("res://ui/logic_analyzer/Radix.gd").Radix
const RadixClass = preload("res://ui/logic_analyzer/Radix.gd")

signal ungroup_requested
signal show_signals_changed(show_signals: bool)
signal radix_changed(radix: Radix)

var line_edit: LineEdit
var button_up: Button
var button_down: Button
var button_show_more: Button
var show_signals: bool = false

func _init(
	text: String,
	height: float
):
	var label_container = HBoxContainer.new()
	var label_buttons_container = VBoxContainer.new()
	label_buttons_container.alignment = BoxContainer.ALIGNMENT_CENTER
	
	button_show_more = Button.new()
	self.button_show_more = button_show_more
	button_show_more.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_down_var.svg")
	button_show_more.button_up.connect(
		func():
			show_signals = !show_signals
			if show_signals:
				button_show_more.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_up_var.svg")
			else:
				button_show_more.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_down_var.svg")
			show_signals_changed.emit(show_signals)
	)
	
	button_up = Button.new()
	self.button_up = button_up
	button_up.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_up.svg")
	label_buttons_container.add_child(button_up)
	
	button_down = Button.new()
	self.button_down = button_down
	button_down.icon = ResourceLoader.load("res://ui/logic_analyzer/icons/icon_arrow_down.svg")
	label_buttons_container.add_child(button_down)
	
	line_edit = LineEdit.new()
	line_edit.custom_minimum_size.y = height
	line_edit.size.y = height
	line_edit.text = text
	
	var line_edit_menu = line_edit.get_menu()
	# Remove useless menu items
	for item_index in [15,14,13,12,11,10]:
		line_edit_menu.remove_item(item_index)
	line_edit_menu.add_item("Разгруппировать", 2281337)
	var radix_popupmenu = PopupMenu.new()
	for radix in Radix.values():
		radix_popupmenu.add_radio_check_item(
			RadixClass.radix_to_string(radix),
			radix # radix is id
		)
	radix_popupmenu.index_pressed.connect(
		func(index):
			for radix in Radix.values():
				if radix_popupmenu.get_item_id(index) == radix:
					radix_popupmenu.set_item_checked(index, true)
					radix_changed.emit(radix)
				else:
					radix_popupmenu.set_item_checked(
						radix_popupmenu.get_item_index(radix),
						false
					)
	)
	
	line_edit_menu.add_submenu_node_item("Основание", radix_popupmenu, 52)
	line_edit_menu.index_pressed.connect(
		func(index):
			if line_edit_menu.get_item_id(index) == 2281337:
				ungroup_requested.emit()
	)
		
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label_container.add_child(button_show_more)
	label_container.add_child(line_edit)
	label_container.add_child(label_buttons_container)
	add_child(label_container)
