extends HSplitContainer

var signals: Array[LA_Signal]
const SIGNAL_ROW_HEIGHT = 70
const BASE_SIGNAL_VALUE_WIDTH = 60
var signal_value_width = BASE_SIGNAL_VALUE_WIDTH
@onready var select_pins_button = get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ButtonHBoxContainer/SelectPinsButton")
@onready var signal_container = get_node("./SignalsPanelContainer/SignalsScrollContainer/SignalsVBoxContainer")
@onready var label_container = get_node("./SignalLabelsPanelContainer/SignalLabelsVBoxContainer")

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
		line_edit.custom_minimum_size = Vector2(0, SIGNAL_ROW_HEIGHT)
		line_edit.text_changed.connect(_on_text_submitted.bind(1))
		line_edit.text = pin.readable_name
		var line_edit_menu = line_edit.get_menu()
		label_container.add_child(line_edit)
		
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
				remove_signal(sig)
		line_edit_menu.id_pressed.connect(callback)
	
func _on_text_submitted(text, id):
	print(text + " " + str(id))

func _on_logic_analyzer_timer_timeout() -> void:
	var current_signal_index = 0
	for sig in signals:
		draw_new_signal_value(sig, current_signal_index, _current_signal_value_index)
		current_signal_index += 1
	_current_signal_value_index += 1
	
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

func remove_signal(LA_Signal):
	signals.erase(LA_Signal)
	LA_Signal.line_edit.queue_free()
	LA_Signal.signal_line.queue_free()
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
	
func _on_timer_delay_line_edit_delay_value_changed(new_value: float) -> void:
	signal_value_width = BASE_SIGNAL_VALUE_WIDTH * new_value
