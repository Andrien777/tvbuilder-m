extends LineEdit


var value: float = 1.0


func _ready() -> void:
	self.text = str(value)


func _on_text_submitted(new_text: String) -> void:
	value = max(float(new_text), 0.0)
	self.text = str(value)


func _on_focus_exited() -> void:
	value = max(float(self.text), 0.0)
	self.text = str(value)
