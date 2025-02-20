extends HBoxContainer


var previousGlobalInput
func _on_mouse_entered() -> void:
	previousGlobalInput = GlobalSettings.disableGlobalInput
	GlobalSettings.disableGlobalInput = true


func _on_mouse_exited() -> void:
	GlobalSettings.disableGlobalInput = previousGlobalInput
