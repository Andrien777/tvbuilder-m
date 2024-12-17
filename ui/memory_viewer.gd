extends Window
var page = 0
var list
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	list = get_node("VBoxContainer/GridContainer")
	close_requested.connect(hide)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func set_page(page):
	self.page = page
	list.display_page(page)
	
func update():
	list.display_page(page)

	
func set_memory(memory):
	if list.memory!=memory:
		page = 0
	list.memory = memory
	list.display_page(page)
	self.visible = true
