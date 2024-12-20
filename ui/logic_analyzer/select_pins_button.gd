extends Button

var is_add_pins_mode_on: bool = false

func _on_pressed() -> void:
	if is_add_pins_mode_on:
		is_add_pins_mode_on = false
		text = "Начать выбор ножек"
	else:
		is_add_pins_mode_on = true
		text = "Завершить выбор ножек"
