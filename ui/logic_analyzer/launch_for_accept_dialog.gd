extends AcceptDialog


@onready var signals_container = %SignalsHSplitContainer

var launch_time_ms = 1000.0
func _ready() -> void:
	var container = HBoxContainer.new()
	var label = Label.new()
	label.text = "Время запуска, мс:"
	var line_edit = LineEdit.new()
	line_edit.text = str(launch_time_ms)
	line_edit.text_changed.connect(
		func(text: String):
			if text.is_valid_float():
				launch_time_ms = float(text)
	)
	container.add_child(label)
	container.add_child(line_edit)
	add_child(container)
	register_text_enter(line_edit)
	
	confirmed.connect(
		func():
			signals_container.is_analysis_in_progress = true
			var time = launch_time_ms / 1000.0
			get_tree().create_timer(time).timeout.connect( 
				func():
					signals_container.is_analysis_in_progress = false 
			)
	)
