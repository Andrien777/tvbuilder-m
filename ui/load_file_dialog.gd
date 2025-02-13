extends FileDialog

@onready var load_file_dialog: FileDialog = $"."

var _on_data_loaded_callback

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: make it remember last load location; doesn't seem to work with native dialogs
	load_file_dialog.current_dir = "user://"
	if OS.has_feature("web"):
		_on_data_loaded_callback = JavaScriptBridge.create_callback(_on_data_loaded)
		var gdcallbacks: JavaScriptObject = JavaScriptBridge.get_interface("gd_callbacks")
		gdcallbacks.dataLoaded = _on_data_loaded_callback

func _on_load_button_pressed() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("loadData()", true)
	else:
		load_file_dialog.visible = true 
	
func _on_file_selected(path: String) -> void:
	SaveManager.load(get_tree().current_scene, path)

func _on_data_loaded(data):
	if (data.size() == 0):
		return
	SaveManager.parse_save_str(get_tree().current_scene, data[0], data[1])
