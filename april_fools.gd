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
var audio_queue = []
var cooldowns = [0, 0, 0, 0, 0]

func commence_tomfoolery():
	print('I solemnly swear that I am up to no good')
	timer = Timer.new()
	timer.one_shot = false
	timer.wait_time = 1
	timer.timeout.connect(check)
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
	
	

func check():
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
	if ComponentManager.obj_list.size() > 2 and ComponentManager.obj_list.values().any(func (obj: CircuitComponent):
		return obj is Switch) and not ComponentManager.obj_list.values().any(func (obj: CircuitComponent):
		return obj is TextLabel):
		if cooldowns[3] == 0:
			audio_queue.push_front(audio_labels)
			cooldowns[3] = 60
		cooldowns[3] -= 1
	else:
		cooldowns[3] = 0
	if WireManager.wire_ghost.visible:
		if randf() < 0.5:
			if !audio_queue.has(audio_rmb_wires):
				audio_queue.push_front(audio_rmb_wires)
		if WireManager.wires.size() > 10:
			if !audio_queue.has(audio_last_wire) and player.stream != audio_last_wire:
				audio_queue.push_front(audio_last_wire)
	if GlobalSettings.CurrentGraphicsMode != LegacyGraphicsMode:
		if cooldowns[4] == 0:
			audio_queue.push_front(audio_min_gr)
			cooldowns[4] = 60
		cooldowns[4] -= 1
	else:
		cooldowns[4] = 0
	if ComponentManager.obj_list.size() > 0:
		var centre = Vector2.ZERO
		for obj: CircuitComponent in ComponentManager.obj_list.values():
			centre += obj.position + obj.hitbox.shape.size/2
		centre /= ComponentManager.obj_list.size()
		if (get_node("/root/RootNode/Camera2D").position - centre).length() > 1000:
			if !audio_queue.has(audio_pan):
				audio_queue.push_front(audio_pan)
	if not audio_queue.is_empty():
		if !player.is_playing():
			var file = audio_queue.pop_back()
			player.stream = file
			player.play()
			if file == audio_pan:
				get_node("/root/RootNode/Camera2D").move_to_centre()

func too_long():
	if !audio_queue.has(audio_too_long) and player.stream != audio_too_long:
		audio_queue.push_back(audio_too_long)
	timer_2.wait_time = 60 + randf_range(-10, 10)
	timer_2.start()
