extends Button

@onready var signals_h_split_container = %SignalsHSplitContainer


func _ready() -> void:
	if signals_h_split_container.is_analysis_in_progress:
		text = "Остановить анализ"
	else:
		text = "Начать анализ"

func _on_pressed() -> void:
	if signals_h_split_container.is_analysis_in_progress:
		text = "Начать анализ" 
		signals_h_split_container.is_analysis_in_progress = false
	else:
		signals_h_split_container.clear_signal_values()
		text = "Остановить анализ"
		signals_h_split_container.is_analysis_in_progress = true
