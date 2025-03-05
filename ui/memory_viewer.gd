extends Window
var page = 0
var list
var memory_name_label
var continuous_update = true
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	list = get_node("VBoxContainer/GridContainer")
	close_requested.connect(hide)
	memory_name_label = get_node("VBoxContainer/HBoxContainer2/RamNameLabel")
	get_node("VBoxContainer/HBoxContainer2/ContinuousUpdate").button_pressed = true



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (continuous_update and visible):
		update()
	if not is_instance_valid(list.memory):
		memory_name_label.text = "Память не выбрана"
		update()

func set_page(page):
	self.page = page
	update()

func update():
	list.display_page(page)
	if is_instance_valid(list.memory):
		memory_name_label.text = "%s (%d)" % [list.memory.readable_name, list.memory.id]
	
func set_memory(memory):
	if list.memory!=memory:
		page = 0
	list.memory = memory
	update()
	list.reset_all_labels_style()
	self.visible = true
