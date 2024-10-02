extends FileDialog

@onready var load_file_dialog: FileDialog = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: make it remember last load location; doesn't seem to work with native dialogs
	load_file_dialog.current_dir = "/"

func _on_load_button_pressed() -> void:
	load_file_dialog.visible = true 
	
func _on_file_selected(path: String) -> void:
	SaveManager.load(get_tree().current_scene, path)
