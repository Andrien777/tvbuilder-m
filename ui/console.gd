extends PanelContainer
@onready var label: RichTextLabel = get_node("./VBoxContainer/RichTextLabel")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func write(text:String, color = Color(1,1,1), prefix = ""):
	if label.get_total_character_count()>label.visible_characters:
		for i in range(100):
			label.remove_paragraph(0)
	var time = Time.get_datetime_dict_from_system()
	label.push_color(color)
	label.add_text("%s %02d:%02d:%02d: %s \n" % [prefix, time.hour, time.minute, time.second, text])
	label.pop()
	


var previousGlobalInputState
func _on_mouse_entered() -> void:
	previousGlobalInputState = GlobalSettings.disableGlobalInput
	GlobalSettings.disableGlobalInput = true


func _on_mouse_exited() -> void:
	GlobalSettings.disableGlobalInput = previousGlobalInputState and GlobalSettings.disableGlobalInput


func _on_focus_entered() -> void:
	previousGlobalInputState = GlobalSettings.disableGlobalInput
	GlobalSettings.disableGlobalInput = true


func _on_focus_exited() -> void:
	GlobalSettings.disableGlobalInput = previousGlobalInputState and GlobalSettings.disableGlobalInput


func _on_button_pressed() -> void:
	self.hide()


func _on_clear_button_pressed() -> void:
	label.clear()
