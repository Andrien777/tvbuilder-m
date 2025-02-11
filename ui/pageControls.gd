extends HBoxContainer

var mem_viewer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ForwardButton.pressed.connect(next_page)
	$BackwardButton.pressed.connect(previous_page)
	$LoadButton.pressed.connect(mem_load)
	mem_viewer = get_node("./../../")
	$UpdateButton.pressed.connect(mem_viewer.update)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func next_page():
	mem_viewer.set_page(mem_viewer.page+1)

func previous_page():
	if mem_viewer.page>0:
		mem_viewer.set_page(mem_viewer.page-1)

func mem_load():
	$FileDialog._on_load_button_pressed()
func _on_mem_load(path):
	var file = FileAccess.open(path,FileAccess.READ)
	var addr=0
	while addr<len(mem_viewer.list.memory.memory_content) and not file.eof_reached():
		mem_viewer.list.memory.memory_content[addr] = file.get_8()
		addr+=1
	file.close()
	mem_viewer.update()
	var grid = get_node("./../GridContainer/")
	if grid and is_instance_valid(grid):
		grid.reset_all_labels_style()
	else:
		InfoManager.write_error("Не удалось очистить выделение в просмотрщике памяти")


func _on_continuous_update_pressed() -> void:
	mem_viewer.continuous_update = !mem_viewer.continuous_update
