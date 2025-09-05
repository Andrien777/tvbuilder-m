extends HBoxContainer

var mem_viewer
var _on_data_bin_loaded_callback
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ForwardButton.pressed.connect(next_page)
	$BackwardButton.pressed.connect(previous_page)
	$LoadButton.pressed.connect(mem_load)
	mem_viewer = get_node("./../../")
	$UpdateButton.pressed.connect(mem_viewer.update)
	if OS.has_feature("web"):
		_on_data_bin_loaded_callback = JavaScriptBridge.create_callback(_on_data_js_loaded)
		var gdcallbacks: JavaScriptObject = JavaScriptBridge.get_interface("gd_callbacks")
		gdcallbacks.dataBinLoaded = _on_data_bin_loaded_callback


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func next_page():
	mem_viewer.set_page(mem_viewer.page+1)

func previous_page():
	if mem_viewer.page>0:
		mem_viewer.set_page(mem_viewer.page-1)

func mem_load():
	if OS.has_feature("web"):
		JavaScriptBridge.eval("loadBinData()", true)
	else:
		mem_viewer.always_on_top = false
		$FileDialog._on_load_button_pressed()
	
func _on_mem_load(path):
	mem_viewer.always_on_top = true
	var file = FileAccess.open(path,FileAccess.READ)
	var addr=0
	while addr<len(mem_viewer.list.memory.memory_content) and not file.eof_reached():
		mem_viewer.list.memory.memory_content[addr] = file.get_8()
		addr+=1
	file.close()
	mem_viewer.update()
	$LoadButton._on_successful_load()
	var grid = get_node("./../GridContainer/")
	if grid and is_instance_valid(grid):
		grid.reset_all_labels_style()
	else:
		InfoManager.write_error("Не удалось очистить выделение в просмотрщике памяти")

func _on_data_js_loaded(args: Array):
	if args.size() == 0:
		return
	var addr=0
	while addr<len(mem_viewer.list.memory.memory_content) and addr < args[0].length:
		mem_viewer.list.memory.memory_content[addr] = args[0].at(addr)
		addr+=1
	mem_viewer.update()
	var grid = get_node("./../GridContainer/")
	if grid and is_instance_valid(grid):
		grid.reset_all_labels_style()
	else:
		InfoManager.write_error("Не удалось очистить выделение в просмотрщике памяти")

func _on_continuous_update_pressed() -> void:
	mem_viewer.continuous_update = !mem_viewer.continuous_update


func _on_file_dialog_canceled() -> void:
	mem_viewer.always_on_top = true
