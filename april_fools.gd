extends Node2D

var ui: CanvasLayer
var timer: Timer
@onready var player: AudioStreamPlayer = $AudioStreamPlayer
var audio_bg
var audio_rmb_wires
var audio_wire_col
var audio_labels
var audio_la
var audio_queue = []

func commence_tomfoolery():
	print('I solemnly swear that I am up to no good')
	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 1
	timer.timeout.connect(check)
	add_child(timer)
	timer.start()
	audio_bg = preload("res://graphics/af_wrong_background_audio.mp3")
	audio_rmb_wires = preload("res://graphics/af_rmb_wires.mp3")
	audio_wire_col = preload("res://graphics/af_wrong_wire_color.mp3")
	audio_labels = preload("res://graphics/af_no_labels.mp3")
	audio_la = preload("res://graphics/af_la_no_on_top.mp3")
	
	

func check():
	if GlobalSettings.bg_color != Color("999902"):
		if audio_queue.front() != audio_bg:
			audio_queue.push_front(audio_bg)
	if GlobalSettings.wire_color != Color(1, 0, 0):
		if audio_queue.front() != audio_wire_col:
			audio_queue.push_front(audio_wire_col)
	if not GlobalSettings.is_LA_always_on_top:
		if audio_queue.front() != audio_la:
			audio_queue.push_front(audio_la)
	if ComponentManager.obj_list.size() > 10 and ComponentManager.obj_list.values().any(func (obj: CircuitComponent):
		return obj is Switch) and not ComponentManager.obj_list.values().any(func (obj: CircuitComponent):
		return obj is TextLabel):
		if audio_queue.front() != audio_labels:
			audio_queue.push_front(audio_labels)
	if WireManager.wire_ghost.visible:
		if randf() < 0.5:
			if audio_queue.front() != audio_rmb_wires:
				audio_queue.push_front(audio_rmb_wires)
		if WireManager.wires.size() > 20:
			OS.alert("Рекомендую использовать режим отображения последнего провода, без него строить схемы очень неудобно")
	if GlobalSettings.CurrentGraphicsMode != LegacyGraphicsMode:
		OS.alert("Ну зачем вы это включили. Тут же не понятно ничего")
	if not audio_queue.is_empty():
		if !player.is_playing():
			player.stream = audio_queue.pop_back()
			player.play()
