extends LineEdit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.text = str(GlobalSettings.historyDepth)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_text_submitted(new_text: String) -> void:
	GlobalSettings.historyDepth = max(int(new_text), 0)
	self.text = str(GlobalSettings.historyDepth)


func _on_focus_exited() -> void:
	GlobalSettings.historyDepth = max(int(self.text), 0)
	self.text = str(GlobalSettings.historyDepth)
