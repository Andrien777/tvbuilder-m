extends FileDialog

@onready var save_file_dialog: FileDialog = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# TODO: make it remember last save location; doesn't seem to work with native dialogs
	save_file_dialog.current_dir = "user://" 
	save_file_dialog.add_filter("*.json")

func _on_save_as_button_pressed() -> void:
	save_file_dialog.visible = true

func _on_file_selected(path: String) -> void:
	SaveManager.save(path)
