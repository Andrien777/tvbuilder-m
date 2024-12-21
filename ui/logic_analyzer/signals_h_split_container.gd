extends HSplitContainer

var signals: Array[LA_Signal]
const SIGNAL_ROW_HEIGHT = 70
const BASE_SIGNAL_VALUE_WIDTH = 100
var signal_value_width = BASE_SIGNAL_VALUE_WIDTH
@onready var select_pins_button = get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ButtonHBoxContainer/SelectPinsButton")
@onready var signal_container = get_node("./SignalsPanelContainer/SignalsScrollContainer/SignalsVBoxContainer")
@onready var scroll_container = get_node("./SignalsPanelContainer/SignalsScrollContainer")
@onready var label_container = get_node("./SignalLabelsPanelContainer/SignalLabelsVBoxContainer")
var timer

var _current_signal_value_index = 1

class LA_Signal:
	var line_edit: LineEdit
	var signal_line: Line2D
	var ic_id: int
	var pin_index: int
	
	func _init(
		line_edit: LineEdit,
		signal_line: Line2D,
		ic_id: int, 
		pin_index: int
	):
		self.line_edit = line_edit
		self.signal_line = signal_line
		self.ic_id = ic_id
		self.pin_index = pin_index
	
	func _to_string() -> String:
		return "Parent ic's id = " + str(ic_id) + "; Pin_index = " + str(pin_index)	

func add_signal(pin: Pin):
	if select_pins_button.is_add_pins_mode_on:
		var line_edit = LineEdit.new()
		line_edit.custom_minimum_size = Vector2(0, SIGNAL_ROW_HEIGHT - 4)
		line_edit.size.y = SIGNAL_ROW_HEIGHT - 4
		line_edit.text_changed.connect(_on_text_submitted.bind(1))
		line_edit.text = pin.readable_name
		var line_edit_menu = line_edit.get_menu()
		label_container.add_child(line_edit)
		pin.sprite.modulate = Color(0, 0.75, 1, 1)
		
		var signal_line_container = Container.new()
		var signal_line = Line2D.new()
		signal_line.add_point(Vector2(0, SIGNAL_ROW_HEIGHT*0.9), _current_signal_value_index)
		signal_line.width = 3
		signal_container.add_child(signal_line)
		
		var sig = LA_Signal.new(
			line_edit,
			signal_line,
			pin.parent.id, 
			pin.index
			)
		signals.append(sig)
		line_edit_menu.add_item("Прекратить отслеживание", 2281337)
		var callback = func(id): 
			if (id == 2281337):
				remove_signal(sig, pin)
		line_edit_menu.id_pressed.connect(callback)
		clear_signal_values()
	
func _on_text_submitted(text, id):
	pass

func _ready() -> void:
	timer = Timer.new() # To move scroll bar
	timer.one_shot = true
	timer.wait_time = 0.001
	timer.timeout.connect(_on_timer_callback)
	add_child(timer)

func _on_logic_analyzer_timer_timeout() -> void:
	var current_signal_index = 0
	#if abs(_current_signal_value_index * signal_value_width / BASE_SIGNAL_VALUE_WIDTH - int(_current_signal_value_index * signal_value_width / BASE_SIGNAL_VALUE_WIDTH)) < 1e-6:
		#var timestamp_line = Line2D.new()
		#timestamp_line.width = 1
		#timestamp_line.default_color = Color.ALICE_BLUE
		#scroll_container.add_child(timestamp_line)
		#timestamp_line.add_point(Vector2(signal_value_width * _current_signal_value_index, 0))
		#timestamp_line.add_point(Vector2(signal_value_width * _current_signal_value_index, scroll_container.size.y))
		#var timestamp_label = Label.new()
		#scroll_container.add_child(timestamp_label)
		#timestamp_label.position = Vector2(100, 100)
		#timestamp_label.text = str(int(_current_signal_value_index * signal_value_width / BASE_SIGNAL_VALUE_WIDTH))
		#timestamp_label.position = Vector2(100, 100)
		#timestamp_label.add_theme_font_size_override("font_size", 10)
		#timestamp_label.position = Vector2(100, 100)
		#timestamp_label.add_theme_color_override("font_color", Color.CRIMSON)
		#timestamp_label.position = Vector2(100, 100)
	for sig in signals:
		draw_new_signal_value(sig, current_signal_index, _current_signal_value_index)
		current_signal_index += 1
	_current_signal_value_index += 1
	timer.start()
	
	
func draw_new_signal_value(sig: LA_Signal, signal_index: int, signal_value_index: int):
	var line = sig.signal_line
	var prev_point = line.points[line.points.size()-1]
	var val = get_current_signal_value(sig)
	
	line.position.y = SIGNAL_ROW_HEIGHT * signal_index
	var new_point_x = signal_value_width * signal_value_index
	signal_container.custom_minimum_size.x = new_point_x

	if val == NetConstants.LEVEL.LEVEL_LOW:
		# If last signal value was high, draw falling edge
		if (int(prev_point.y) % SIGNAL_ROW_HEIGHT == SIGNAL_ROW_HEIGHT*0.1):
			line.add_point(Vector2(prev_point.x, SIGNAL_ROW_HEIGHT*0.9))
		line.add_point(Vector2(new_point_x, SIGNAL_ROW_HEIGHT*0.9))
	else:
		# If last signal value was low, draw rising edge
		if (int(prev_point.y) % SIGNAL_ROW_HEIGHT == SIGNAL_ROW_HEIGHT*0.9):
			line.add_point(Vector2(prev_point.x, SIGNAL_ROW_HEIGHT*0.1))
		line.add_point(Vector2(new_point_x, SIGNAL_ROW_HEIGHT*0.1))

func get_current_signal_value(sig: LA_Signal) -> NetConstants.LEVEL:
	for i: Pin in NetlistClass.nodes.keys():
		if i.index == sig.pin_index && i.parent.id == sig.ic_id:
			return i.state
	push_error("Logic Analyzer couldn't find Pin " + str(sig) + " in the netlist")
	return NetConstants.LEVEL.LEVEL_Z # Pin is inexistent

func remove_signal(sig_to_del: LA_Signal, pin: Pin):
	pin.sprite.modulate = Color(1, 1, 1, 1)
	signals.erase(sig_to_del)
	sig_to_del.line_edit.queue_free()
	sig_to_del.signal_line.queue_free()
	# Move other lines to their new places
	var signal_index = 0
	for sig in signals: 
		sig.signal_line.position.y = SIGNAL_ROW_HEIGHT * signal_index
		signal_index += 1
		
func clear_signal_values():
	for sig in signals:
		var line = sig.signal_line
		line.clear_points()
		line.add_point(Vector2(0, SIGNAL_ROW_HEIGHT*0.9), _current_signal_value_index)
	_current_signal_value_index = 1
	scroll_container.scroll_horizontal = 0
	signal_container.custom_minimum_size.x = 0
	for child in scroll_container.get_children():
		if child.is_class("Line2D"):
			child.clear_points()
			child.queue_free()
		elif child.is_class("Label"):
			child.queue_free()
	
func _on_timer_delay_line_edit_delay_value_changed(new_value: float) -> void:
	signal_value_width = BASE_SIGNAL_VALUE_WIDTH * new_value
	clear_signal_values()

func _on_timer_callback():
	scroll_container.scroll_horizontal = scroll_container.get_h_scroll_bar().max_value
