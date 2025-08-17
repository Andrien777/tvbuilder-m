extends Window


func _on_close_requested() -> void:
	hide()


func _ready() -> void:
	hide()
	call_deferred("init") 
	
func init():
	always_on_top = GlobalSettings.is_LA_always_on_top
	if OS.has_feature("web"):
		$RootVBoxContainer/ButtonHBoxContainer/SaveButton.visible = false
		$RootVBoxContainer/ButtonHBoxContainer/LoadButton.visible = false
		$RootVBoxContainer/ButtonHBoxContainer/AlwaysOnTopCheckBox.visible = false
