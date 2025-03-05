extends CircuitComponent
class_name DS1008
var inputs
var outputs
var fifo: Array[Array]
var delay = 1
var settings_popup
var popup_style
var text_line
var lbl


func initialize(spec: ComponentSpecification, ic=null)->void:
	super.initialize(spec, ic)
	if(ic!=null and "content" in ic):
		self.delay = int(ic.content)
		text_line.text = str(delay)

func _init() -> void:
	self.input_pickable = true
	settings_popup = Panel.new()
	popup_style = StyleBoxFlat.new()
	popup_style.bg_color =  Color.DIM_GRAY
	popup_style.bg_color.a = 0.9
	popup_style.set_corner_radius_all(15)
	settings_popup.size = Vector2(250,50)
	settings_popup.add_theme_stylebox_override("panel", popup_style)
	settings_popup.visible = false
	settings_popup.z_index = 5
	
	text_line = LineEdit.new()
	text_line.context_menu_enabled = false
	text_line.max_length = 4
	text_line.text = "1"
	text_line.text_changed.connect(on_text_update)
	text_line.position = Vector2(150,10)
	text_line.z_index = 6
	
	lbl = Label.new()
	lbl.text = "Задержка: "
	lbl.position = Vector2(10,15)
	lbl.z_index = 6
	
	settings_popup.add_child(text_line)
	settings_popup.add_child(lbl)
	add_child(settings_popup)
	
	inputs = [1, 3, 6, 8, 10, 14, 16, 18]
	outputs = [2, 4, 7, 9, 11, 13, 15, 17]
	fifo = [[], [], [], [], [], [], [], []]


func _rmb_action():
	settings_popup.global_position = get_global_mouse_position()
	settings_popup.visible =!settings_popup.visible
	if(settings_popup.visible):
		GlobalSettings.disableGlobalInput = true
	else:
		GlobalSettings.disableGlobalInput = false

func on_text_update(new_text:String):
	if(new_text.is_valid_int() and int(new_text) > 0):
		var del = int(new_text)
		delay = del
		for i in range(8):
			if not fifo[i].is_empty():
				while fifo[i].size() > delay:
					fifo[i].pop_front()
	else:
		popup_style.bg_color =  Color.BROWN
		
func _process_signal():
	pin(12).set_low()
	pin(5).set_high()
	for i in range(8):
		fifo[i].push_front(pin(inputs[i]).state)
		if fifo[i].size() == delay + 1:
			pin(outputs[i]).state = fifo[i].pop_back()

func to_json_object() -> Dictionary:
	return {
		"id": id,
		"name": readable_name,
		"position": position,
		"content": delay
	}
