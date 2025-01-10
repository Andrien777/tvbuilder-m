extends Button

var is_analysis_in_progress: bool = false

func _ready() -> void:
	if is_analysis_in_progress:
		text = "Остановить анализ"
	else:
		text = "Начать анализ"

func _on_pressed() -> void:
	if is_analysis_in_progress:
		text = "Начать анализ" 
		is_analysis_in_progress = false
	else:
		text = "Остановить анализ"
		is_analysis_in_progress = true
