extends HBoxContainer

var mem_viewer
var _on_data_bin_loaded_callback
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ForwardButton.pressed.connect(next_page)
	$BackwardButton.pressed.connect(previous_page)
	mem_viewer = get_node("./../../../../")
	$UpdateButton.pressed.connect(mem_viewer.memory_update)
	$TextEdit.text_changed.connect(validate_text)
	$TextEdit.text_submitted.connect(set_page)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func next_page():
	mem_viewer.set_memory_page(mem_viewer.memory_page+1)
	
func validate_text(text: String):
	if text.is_valid_int() and int(text) >= 0:
		pass
	else:
		$TextEdit.text = ""

func set_page(text):
	mem_viewer.set_memory_page(int(text))

func previous_page():
	if mem_viewer.memory_page>0:
		mem_viewer.set_memory_page(mem_viewer.memory_page-1)

func _on_continuous_update_pressed() -> void:
	mem_viewer.continuous_memory_update = !mem_viewer.continuous_memory_update
