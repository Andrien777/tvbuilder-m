extends Timer

const START_STOP_BUTTON_PATH = "../RootVBoxContainer/ButtonHBoxContainer/StartStopAnalysisButton"
@onready var start_stop_button = get_node(START_STOP_BUTTON_PATH)

func _ready() -> void:
	if is_stopped():
		start_stop_button.text = "Начать анализ"
	else:
		start_stop_button.text = "Остановить анализ"

func _on_button_2_pressed() -> void:
	if is_stopped():
		start_stop_button.text = "Остановить анализ"
		start()
	else:
		start_stop_button.text = "Начать анализ" 
		stop()

func _on_timer_delay_line_edit_delay_value_changed(new_value: float) -> void:
	wait_time = new_value
