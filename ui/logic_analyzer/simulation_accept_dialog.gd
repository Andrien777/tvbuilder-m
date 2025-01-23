extends AcceptDialog


@onready var signals_container = %SignalsHSplitContainer


var sim_time_ms = 1000.0
func _ready() -> void:
	var container = HBoxContainer.new()
	var label = Label.new()
	label.text = "Время симуляции, мс:"
	var line_edit = LineEdit.new()
	line_edit.text = str(sim_time_ms)
	line_edit.text_changed.connect(
		func(text: String):
			print(text)
			if text.is_valid_float():
				sim_time_ms = float(text)
			print(sim_time_ms)
	)
	container.add_child(label)
	container.add_child(line_edit)
	add_child(container)
	register_text_enter(line_edit)
	
	confirmed.connect(
		func():
			signals_container.simulate(sim_time_ms)
	)
