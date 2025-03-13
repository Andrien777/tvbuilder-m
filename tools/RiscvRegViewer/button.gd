extends Button
var timer: Timer

func _ready():
	timer = Timer.new()
	timer.wait_time = 1
	timer.one_shot = true
	timer.timeout.connect(reset_color)
	add_child(timer)

func _on_successful_load():
	add_theme_color_override("font_color", Color(0, 1, 0))
	add_theme_color_override("font_hover_color", Color(0, 1, 0))
	text = "Успешно загружено"
	timer.start()

func reset_color():
	remove_theme_color_override("font_color")
	remove_theme_color_override("font_hover_color")
	text = "Загрузить образ памяти"
