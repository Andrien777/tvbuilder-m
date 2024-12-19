extends Window
var page = 0
var list
var memory_name_label
var continuous_update = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	list = get_node("VBoxContainer/GridContainer")
	close_requested.connect(hide)
	memory_name_label = get_node("VBoxContainer/HBoxContainer2/RamNameLabel")



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if (continuous_update):
		update()
func set_page(page):
	self.page = page
	update()
	
func update():
	list.display_page(page)
	memory_name_label.text = list.memory.readable_name
	
func set_memory(memory):
	if list.memory!=memory:
		page = 0
	list.memory = memory
	update()
	self.visible = true
