extends CircuitComponent
class_name FrequencyGenerator
var timer
var text_line
var settings_popup
var enable_button
var enabled = 0
var popup_style
var freq_label
func _init():
	display_name_label = false
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.input_pickable = true
	settings_popup = Panel.new()
	freq_label = Label.new()
	freq_label.text = "f = 1 Гц"
	freq_label.position = Vector2(10, 20)
	if GlobalSettings.LegacyGraphics:
		freq_label.visible =false
	else:
		freq_label.visible = true
	popup_style = StyleBoxFlat.new()
	popup_style.bg_color =  Color.DIM_GRAY
	popup_style.bg_color.a = 0.9
	popup_style.set_corner_radius_all(15)
	settings_popup.size = Vector2(150,100)
	settings_popup.add_theme_stylebox_override("panel", popup_style)
	settings_popup.visible = false
	
	text_line = LineEdit.new()
	text_line.context_menu_enabled = false
	text_line.max_length = 4
	text_line.text = "1"
	text_line.text_changed.connect(on_text_update)
	text_line.position = Vector2(20,40)
	
	enable_button = CheckButton.new()
	enable_button.pressed.connect(on_enable_button_press)
	enable_button.position = Vector2(15,0)
	enable_button.text = "Включить "
	
	timer = Timer.new()
	timer.one_shot = false
	timer.timeout.connect(on_timer_timeout)
	timer.wait_time = 1
	add_child(timer)
	settings_popup.add_child(text_line)
	settings_popup.add_child(enable_button)
	add_child(settings_popup)
	add_child(freq_label)
	start_timer()
	pin(1).set_low()
	pin(2).set_high()


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


func stop_timer(): # might be useful in case graphics need to hook into timer events
	timer.stop()
func start_timer():
	timer.start()
func on_timer_timeout():
	if(enabled):
		if(pin(1).high):
			pin(1).set_low()
			pin(2).set_high()
		else:
			pin(1).set_high()
			pin(2).set_low()
func on_text_update(new_text:String):
	if(new_text.is_valid_float()):
		var freq = float(new_text)
		if(freq>0):
			timer.wait_time = 1/(freq*2.0)
			freq_label.text = "f = "+ str(freq) + " Гц"
			popup_style.bg_color =  Color.DIM_GRAY
	else:
		popup_style.bg_color =  Color.BROWN
func on_enable_button_press():
	enabled = !enabled
	if(!enabled):
		pin(1).set_low()
		
func change_graphics_mode(mode:GlobalSettings.GraphicsMode):
	super.change_graphics_mode(mode)
	if mode==GlobalSettings.GraphicsMode.Legacy:
		freq_label.visible = false
	elif mode== GlobalSettings.GraphicsMode.Default:
		freq_label.visible = true

func _process(delta: float) -> void: # Just to disable deletion on backspace while popup is open
	if is_dragged && Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT): # TODO: Remove this overload
		self.global_position = get_global_mouse_position() + drag_offset
	else:
		self.is_dragged = false
		snap_to_grid()
	if Input.is_action_pressed("delete_component") and self.is_mouse_over and settings_popup.visible == false :
		Input.action_release("delete_component")
		ComponentManager.remove_object(self)
		queue_free()
		
