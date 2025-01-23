extends Button

@onready var start_stop_analysis_button = get_node("../StartStopAnalysisButton")
@onready var start_for_line_edit = get_node("../StartForLineEdit")


func _on_pressed() -> void:
	start_stop_analysis_button.is_analysis_in_progress = true
	var time = start_for_line_edit.value
	get_tree().create_timer(time).timeout.connect( 
		func():
			start_stop_analysis_button.is_analysis_in_progress = false 
	)
