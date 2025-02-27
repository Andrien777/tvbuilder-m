extends CircuitComponent
class_name FrequencyGenerator
var timer
var text_line: LineEdit
var imp_line: LineEdit
var hz_label
var imp_label
var settings_popup
var enable_button
var turbo_button
var turbo = false
var enabled = 0
var imp_counter = -1
var popup_style
var freq_label = Label.new()
func _init():
	display_name_label = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.input_pickable = true
	settings_popup = Panel.new()
	freq_label.text = "f = 1 Гц"
	freq_label.position = Vector2(10, 20)
	if GlobalSettings.CurrentGraphicsMode == LegacyGraphicsMode:
		freq_label.visible = false
	else:
		freq_label.visible = true
	popup_style = StyleBoxFlat.new()
	popup_style.bg_color =  Color.DIM_GRAY
	popup_style.bg_color.a = 0.9
	popup_style.set_corner_radius_all(15)
	settings_popup.size = Vector2(250,150)
	settings_popup.add_theme_stylebox_override("panel", popup_style)
	settings_popup.visible = false
	settings_popup.z_index = 5
	
	text_line = LineEdit.new()
	text_line.context_menu_enabled = false
	text_line.max_length = 4
	text_line.text = "1"
	text_line.text_changed.connect(on_text_update)
	text_line.position = Vector2(20,100)
	text_line.z_index = 6
	
	hz_label = Label.new()
	hz_label.text = "Гц"
	hz_label.position = Vector2(90,105)
	hz_label.z_index = 6
	
	imp_line = LineEdit.new()
	imp_line.context_menu_enabled = false
	imp_line.max_length = 4
	imp_line.text = ""
	imp_line.text_changed.connect(on_imp_text_update)
	imp_line.position = Vector2(20,60)
	imp_line.z_index = 6
	
	imp_label = Label.new()
	imp_label.text = "импульсов"
	imp_label.position = Vector2(90,65)
	imp_label.z_index = 6
	
	enable_button = CheckButton.new()
	enable_button.pressed.connect(on_enable_button_press)
	enable_button.position = Vector2(15,0)
	enable_button.text = "Включить "
	enable_button.z_index = 6
	
	turbo_button = CheckButton.new()
	turbo_button.pressed.connect(on_turbo_button_press)
	turbo_button.position = Vector2(15,30)
	turbo_button.text = "Макс. частота "
	turbo_button.z_index = 6
	
	timer = Timer.new()
	timer.one_shot = false
	timer.timeout.connect(on_timer_timeout)
	timer.wait_time = 0.5
	add_child(timer)
	settings_popup.add_child(text_line)
	settings_popup.add_child(enable_button)
	settings_popup.add_child(turbo_button)
	settings_popup.add_child(imp_line)
	settings_popup.add_child(imp_label)
	add_child(settings_popup)
	add_child(freq_label)
	settings_popup.add_child(hz_label)
	pin(1).set_low()
	pin(2).set_high()

func initialize(spec: ComponentSpecification, ic = null)->void:
	super.initialize(spec, ic)
	sprite.texture.normal_texture = preload("res://graphics/metal_normal.jpg")
	sprite.texture.specular_texture = preload("res://graphics/Metal_Galvanized_001_roughness.jpg")
# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#super._process(delta)
func _input_event(viewport: Viewport, event: InputEvent, shape_idx: int) -> void:
	super._input_event(viewport,event, shape_idx)
	if event is InputEventMouseButton and event.is_pressed() and event.button_index == MOUSE_BUTTON_RIGHT:
		settings_popup.global_position = get_global_mouse_position()
		settings_popup.visible =!settings_popup.visible
		if(settings_popup.visible):
			GlobalSettings.disableGlobalInput = true
		else:
			GlobalSettings.disableGlobalInput = false


func _process_signal():
	if enabled and turbo:
		if(pin(1).high) and imp_counter != 0:
			pin(1).set_low()
			pin(2).set_high()
			if imp_counter > 0:
				imp_counter -= 1
		else:
			pin(1).set_high()
			pin(2).set_low()
	if imp_counter == 0:
		enabled = 0
		enable_button.button_pressed = false
		stop_timer()
		imp_counter = int(imp_line.text)


func stop_timer(): # might be useful in case graphics need to hook into timer events
	timer.stop()
func start_timer():
	timer.start()
func on_timer_timeout():
	if(enabled and not turbo and imp_counter != 0):
		if(pin(1).high):
			pin(1).set_low()
			pin(2).set_high()
			if imp_counter > 0:
				imp_counter -= 1
		else:
			pin(1).set_high()
			pin(2).set_low()
func on_text_update(new_text:String):
	if(new_text.is_valid_float()):
		var freq = float(new_text)
		if(freq>0):
			stop_timer()
			timer.wait_time = 1/(freq*2.0)
			start_timer()
			freq_label.text = "f = "+ str(freq) + " Гц"
			popup_style.bg_color =  Color.DIM_GRAY
	else:
		popup_style.bg_color =  Color.BROWN
func on_imp_text_update(new_text:String):
	if new_text.is_valid_int():
		var imp = int(new_text)
		if imp > 0:
			imp_counter = imp
		else:
			imp_counter = -1
			imp_line.text = ""
	else:
		imp_counter = -1
		imp_line.text = ""
	
	
func on_enable_button_press():
	enabled = !enabled
	if(!enabled):
		pin(1).set_low()
		pin(2).set_high()
	else:
		start_timer()

func on_turbo_button_press():
	turbo = !turbo
	if(turbo):
		text_line.visible = false
		hz_label.visible = false
		stop_timer()
	else:
		text_line.visible = true
		hz_label.visible = true
		start_timer()
		
func change_graphics_mode(mode):
	super.change_graphics_mode(mode)
	if mode==LegacyGraphicsMode:
		freq_label.visible = false
	elif mode==DefaultGraphicsMode:
		freq_label.visible = true
		
