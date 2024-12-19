extends FileDialog

@onready var load_file_dialog: FileDialog = $"."
var handler
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: make it remember last load location; doesn't seem to work with native dialogs
	load_file_dialog.current_dir = "/"
	handler = get_node("./../")
	file_selected.connect(_on_file_selected)
func _on_load_button_pressed() -> void:
	load_file_dialog.visible = true 
	
func _on_file_selected(path: String) -> void:
	handler._on_mem_load(path)
