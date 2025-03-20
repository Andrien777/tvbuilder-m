extends Node2D

var ui: CanvasLayer
var timer: Timer
var timer_2: Timer
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
var audio_bg
var audio_rmb_wires
var audio_wire_col
var audio_labels
var audio_la
var audio_last_wire
var audio_min_gr
var audio_pan
var audio_too_long
var audio_led_colors
var audio_positions
var audio_queue = []
var cooldowns = [0, 0, 0, 0, 0, 0, 0]
var thread_check: Thread
@onready var panel = get_node("/root/RootNode/UiCanvasLayer/HBoxContainer")
@onready var label = get_node("/root/RootNode/UiCanvasLayer/HBoxContainer/VBoxContainer/PanelContainer/HelperText")

func commence_tomfoolery():
	panel.visible = false
	label.text = ""
	thread_check = Thread.new()
	thread_check.start(thread_check_task)
	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 1
	timer.timeout.connect(check_main_thread)
	add_child(timer)
	timer_2 = Timer.new()
	timer_2.one_shot = false
	timer_2.wait_time = 60 + randf_range(-10, 10)
	timer_2.timeout.connect(too_long)
	add_child(timer_2)
	timer_2.start()
	timer.start()
	audio_bg = preload("res://graphics/af_wrong_background_audio.mp3")
	audio_rmb_wires = preload("res://graphics/af_rmb_wires.mp3")
	audio_wire_col = preload("res://graphics/af_wrong_wire_color.mp3")
	audio_labels = preload("res://graphics/af_no_labels.mp3")
	audio_la = preload("res://graphics/af_la_no_on_top.mp3")
	audio_last_wire = preload("res://graphics/af_last_wire_mode.mp3")
	audio_min_gr = preload("res://graphics/af_minimalistic_graphics.mp3")
	audio_pan = preload("res://graphics/af_pan_too_far.mp3")
	audio_too_long = preload("res://graphics/af_working_too_long.mp3")
	audio_led_colors = preload("res://graphics/af_led_colors.mp3")
	audio_positions = preload("res://graphics/af_wrong_led_switch_position.mp3")
	
func thread_check_task():
	while true:
		check()
		await get_tree().create_timer(1).timeout

func check():
	var flag_lbl_possible = false
	var flag_lbl = true
	var centre = Vector2.ZERO
	var led_color_cnt = [0, 0, 0, 0]
	var lowest_led_y = -INF
	var lowest_y = -INF
	var highest_switch_y = INF
	var highest_y = INF
	if ComponentManager.obj_list.size() > 0:
		for obj in ComponentManager.obj_list.values():
			centre += obj.position + obj.hitbox.shape.size/2
			if obj is Switch:
				flag_lbl_possible = true
				if obj.position.y < highest_switch_y:
					highest_switch_y = obj.position.y
			elif obj is ICButton:
				if obj.position.y < highest_switch_y:
					highest_switch_y = obj.position.y
			elif obj is TextLabel:
				flag_lbl = false
			elif obj is LED:
				led_color_cnt[0] += 1
				if obj.position.y + obj.hitbox.shape.size.y > lowest_led_y:
					lowest_led_y = obj.position.y + obj.hitbox.shape.size.y
			elif obj is LED_blue:
				led_color_cnt[1] += 1
				if obj.position.y + obj.hitbox.shape.size.y > lowest_led_y:
					lowest_led_y = obj.position.y + obj.hitbox.shape.size.y
			elif obj is LED_red:
				led_color_cnt[2] += 1
				if obj.position.y + obj.hitbox.shape.size.y > lowest_led_y:
					lowest_led_y = obj.position.y + obj.hitbox.shape.size.y
			elif obj is LED_yellow:
				led_color_cnt[3] += 1
				if obj.position.y + obj.hitbox.shape.size.y > lowest_led_y:
					lowest_led_y = obj.position.y + obj.hitbox.shape.size.y
			else:
				if obj.position.y + obj.hitbox.shape.size.y > lowest_y:
					lowest_y = obj.position.y + obj.hitbox.shape.size.y
				if obj.position.y < highest_y:
					highest_y = obj.position.y
		led_color_cnt.sort()
		if led_color_cnt[3] + led_color_cnt[2] + led_color_cnt[1] + led_color_cnt[0] >= 3 and led_color_cnt[2] == 0:
			if cooldowns[5] == 0:
				audio_queue.push_front(audio_led_colors)
				cooldowns[5] = 60
			cooldowns[5] -= 1
		else:
			cooldowns[5] = 0
		centre /= ComponentManager.obj_list.size()
	if GlobalSettings.bg_color != Color("999902"):
		if cooldowns[0] == 0:
			audio_queue.push_front(audio_bg)
			cooldowns[0] = 60
		cooldowns[0] -= 1
	else:
		cooldowns[0] = 0
	if GlobalSettings.wire_color != Color(1, 0, 0):
		if cooldowns[1] == 0:
			audio_queue.push_front(audio_wire_col)
			cooldowns[1] = 60
		cooldowns[1] -= 1
	else:
		cooldowns[1] = 0
	if not GlobalSettings.is_LA_always_on_top:
		if cooldowns[2] == 0:
			audio_queue.push_front(audio_la)
			cooldowns[2] = 60
		cooldowns[2] -= 1
	else:
		cooldowns[2] = 0
	if ComponentManager.obj_list.size() > 2 and flag_lbl and flag_lbl_possible:
		if cooldowns[3] == 0:
			audio_queue.push_front(audio_labels)
			cooldowns[3] = 60
		cooldowns[3] -= 1
	else:
		cooldowns[3] = 0
	if GlobalSettings.CurrentGraphicsMode != LegacyGraphicsMode:
		if cooldowns[4] == 0:
			audio_queue.push_front(audio_min_gr)
			cooldowns[4] = 60
		cooldowns[4] -= 1
	else:
		cooldowns[4] = 0
	if highest_switch_y < max(lowest_y, lowest_led_y) or min(highest_y, highest_switch_y) < lowest_led_y:
		if cooldowns[6] == 0:
			audio_queue.push_front(audio_positions)
			cooldowns[6] = 60
		cooldowns[6] -= 1
	else:
		cooldowns[6] = 0
	if ComponentManager.obj_list.size() > 0:
		if (get_node("/root/RootNode/Camera2D").position - centre).length() > 1000:
			if !audio_queue.has(audio_pan):
				audio_queue.push_front(audio_pan)

func check_main_thread():
	if !player.is_playing():
		panel.visible = false
	if not audio_queue.is_empty():
		if !player.is_playing():
			var file = audio_queue.pop_back()
			player.stream = file
			panel.visible = true
			match file:
				audio_bg:
					label.text = """Что это за цвет заднего плана? Цвет заднего фона должен выглядеть
					как текстолитовая плата, это не квартус, там очень плохо рисуются микросхемы,
					много недоработок. Вы зачем ставите такой цвет? Я в таком виде проверять
					ничего не буду. Даже не пробуйте мне показывать такую схему!"""
				audio_labels:
					label.text = """Ну и что это такое? Где все подписи? Как здесь что-то можно
					понять? Сколько раз вам повторять, все разряды, все переключатели,
					все должно быть подписано! Вот что это за переключатель? Что он делает?
					Нельзя так схемы составлять! Срочно все подпишите."""
				audio_min_gr:
					label.text = """Зачем вы включили этот режим? Выключите немедленно! Его
					вообще не должно быть в программе, как его можно использовать,
					там же ничего не понятно! Отвратительная графика. Понимаете, все
					преимущество этой программы перед квартус или протеус в том, что в
					них ужасное отображение графики. У нас все как по-настоящему, как в
					реальности. Если действительно собирать схему, все вот так и будет
					выглядеть. Не надо включать этот режим, никогда. Не трогайте его. Оно вам не нужно."""
				audio_led_colors:
					label.text = """Используйте светодиоды разных цветов для важных разрядов.
					Так будет проще понять на что следует обратить внимание.
					Согласитесь, сложно ведь когда все одного цвета, все однообразно.
					Специально для вас есть светодиоды разных цветов, только делайте
					так чтобы видно было."""
				audio_pan:
					label.text = """Вы потерялись с возможностью перемещения поля? Для
					перемещения поля необходимо зажать ЛКМ - левую кнопку мыши - в
					любом месте поля и перетащить мышь. Только на проводах и микросхемах
					не надо зажимать кнопку мыши. А еще в логическом анализаторе не надо,
					ну вы поняли. Не разберетесь наверное, давайте я вас перенесу в центр
					поля, раз потерялись."""
				audio_too_long:
					var arr = ["TXT_TAKING_TOO_LONG_MESSAGE", """Π•Ρ€Ρ�Ρ‹ Ρ�Ρ‹ Ρ€Ρ‰Ρ† Π�Ρ‰Π²Ρ‰ΠµΓΆΒ€Β™Ρ‹ Π“Π¨ Ρ‹Ρ�Ρ�Ρ�Ρ‚ΠΏ Ρ„Ρ‚Π²
					Π·Ρ‰Ρ‹Ρ�ΠµΡ�Ρ‰Ρ‚Ρ�Ρ‚ΠΏ Ρ‹Π½Ρ‹ΠµΡƒΡ� Ρ†Ρ‰ΠΊΠ»Ρ‹Π– Π¤Ρ‚Ρ�Ρ€Ρ‰ΠΊΡ‹Π± Π¬Ρ„ΠΊΠΏΡ�Ρ‚Ρ‹Π±
					Ρ„Ρ‚Π² Π΅Ρ‰Ρ‚ΠµΡ„Ρ�Ρ‚ΡƒΠΊΡ‹Ρ� ΠΆΡ‰Ρ† ΠµΡ€Ρ„Πµ Π¨ Π³Ρ‚Π²ΡƒΠΊΡ‹ΠµΡ„Ρ‚Π² ΠµΡ€Ρ�Ρ‹Π±
					Π¨ΓΆΒ€Β™ΠΌΡƒ Ρ€Ρ„Π² Ρ„ Ρ�Π³Ρ�Ρ€ ΡƒΡ„Ρ‹Ρ�ΡƒΠΊ ΠµΡ�Ρ�Ρƒ Ρ�ΠΊΡ„Π°ΠµΡ�Ρ‚ΠΏ Π“Π¨ ΠµΡ€Ρ„Πµ
					Ρ�Ρ‹ Π·Π΄Ρ„Ρ�ΡƒΠ² ΡƒΡ‡Ρ„Ρ�ΠµΠ΄Π½ Ρ€Ρ‰Ρ† Π¨ Ρ†Ρ„Ρ‚Πµ Ρ�Πµ ΠµΡ‰ ΠΈΡƒΡ� Π•Ρ€Ρƒ Ρ‹Π½Ρ‹ΠµΡƒΡ�
					Ρ�Ρ‹ Ρ‹Ρ�Ρ�Π·Π΄ΡƒΠ± ΠΈΠ³Πµ Π³Ρ‚ΠµΡ�Π΄ Π¨ ΠΏΠΊΡ‰Π»Π»ΡƒΠ² Ρ€Ρ‰Ρ† Ρ�Πµ Ρ†Ρ‰ΠΊΠ»Ρ‹ Ρ�Πµ Π°ΡƒΠ΄Πµ
					Ρ�Ρ‰Ρ‚Π°Π³Ρ‹Ρ�Ρ‚ΠΏ Ρ„Ρ‚Π² Π³Ρ‚Ρ�Ρ‚ΠµΠ³Ρ�ΠµΡ�ΠΌΡƒΡ�"""]
					label.text = arr[randi_range(0, 1)]
				audio_la:
					label.text = """В логическом анализаторе есть очень важная галочка. Ее я
					настоятельно рекомендую ВСЕГДА держать включенной.
					Пожалуйста, убедитесь, что эта галочка у вас выставлена.
					Это очень важно!"""
				audio_last_wire:
					label.text = """У нас в программе есть очень странный графический режим. Его
					вообще не должно быть в программе, как его можно использовать,
					там же ничего не понятно! Отвратительная графика. Понимаете, все
					преимущество этой программы перед квартус или протеус в том, что в
					них ужасное отображение графики. У нас все как по-настоящему, как в
					реальности. Если действительно собирать схему, все вот так и будет
					выглядеть. Не надо включать этот режим, никогда. Не трогайте его. Оно вам не нужно.
					А, да. Если в схеме много проводов, рекомендую использовать режим
					отображения только последнего провода. Он позволяет удобно работать на сложных схемах.
					Даже если у вас схема не очень сложная, все равно рекомендую использовать этот режим."""
				audio_positions:
					label.text = """Вам же повторяли кучу раз, светодиоды должны быть
					сверху схемы, переключатели снизу схемы. Вы когда компьютером
					пользуетесь, у вас клавиатура где находится? А монитор где?
					Разве у вас клавиатура над монитором? Все переключатели обязательно
					находятся снизу микросхемы, все индикаторы сверху, так удобнее
					читать схему. Это же простейшее требование, но все почему-то постоянно делают
					одну и ту же ошибку. Быстро все переделайте."""
				audio_rmb_wires:
					label.text = """Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do
					eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad
					minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip
					ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate
					velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat
					cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."""
				audio_wire_col:
					label.text = """Кто вас просил изменить стандартный цвет проводов? Провода в
					программе должны быть медного цвета, какие они и есть. Вы, если бы собирали стенд
					по-настоящему, именно так все и увидели бы. Зачем вот это все устраивать?
					Нет, так не пойдет, возвращайте обратно медный цвет."""
			player.play()
			if file == audio_pan:
				get_node("/root/RootNode/Camera2D").move_to_centre()
	if WireManager.wire_ghost.visible:
		if randf() < 0.5:
			if !audio_queue.has(audio_rmb_wires):
				audio_queue.push_front(audio_rmb_wires)
		if WireManager.wires.size() > 10:
			if !audio_queue.has(audio_last_wire) and player.stream != audio_last_wire:
				audio_queue.push_front(audio_last_wire)

func too_long():
	if !audio_queue.has(audio_too_long) and player.stream != audio_too_long:
		audio_queue.push_back(audio_too_long)
	timer_2.wait_time = 60 + randf_range(-10, 10)
	timer_2.start()

func _exit_tree() -> void:
	if thread_check:
		thread_check.wait_to_finish()
