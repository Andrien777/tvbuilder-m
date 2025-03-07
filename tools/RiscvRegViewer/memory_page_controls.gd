extends HBoxContainer

var mem_viewer
var _on_data_bin_loaded_callback
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ForwardButton.pressed.connect(next_page)
	$BackwardButton.pressed.connect(previous_page)
	$StartButton.pressed.connect(first_page)
	mem_viewer = get_node("./../../../../")
	$UpdateButton.pressed.connect(mem_viewer.memory_update)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func next_page():
	mem_viewer.set_memory_page(mem_viewer.memory_page+1)
	
func first_page():
	mem_viewer.set_memory_page(0)

func previous_page():
	if mem_viewer.memory_page>0:
		mem_viewer.set_memory_page(mem_viewer.memory_page-1)

func _on_continuous_update_pressed() -> void:
	mem_viewer.continuous_memory_update = !mem_viewer.continuous_memory_update
