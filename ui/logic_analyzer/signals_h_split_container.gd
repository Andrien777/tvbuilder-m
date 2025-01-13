extends HSplitContainer

const SIGNAL_ROW_HEIGHT = 70
const SIGNAL_COLORS: Array[Color] = [
	Color(1,1,1),
	Color(0.069, 0.048, 0.609),
	Color(0.820, 0.097, 0.060),
	Color(0.587, 0.528, 0.102),
	Color(0.120, 0.557, 0.283),
	Color(0.304, 0.075, 0.764),
	Color(0.994, 0.561, 0.907),
	Color(0.013, 0.940, 0.604),
]
var color_index = 0
var signals: Array[LA_Signal]
var signal_values_zoom_factor: float = 1.0:
	set = set_signal_values_zoom_factor

@onready var select_pins_button = get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ButtonHBoxContainer/SelectPinsButton")
@onready var start_stop_analysis_button = get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ButtonHBoxContainer/StartStopAnalysisButton")
@onready var signal_container = get_node("./SignalsPanelContainer/SignalsScrollContainer/SignalsVBoxContainer")
@onready var scroll_container = get_node("./SignalsPanelContainer/SignalsScrollContainer")
@onready var label_container = get_node("./SignalLabelsPanelContainer/SignalLabelsVBoxContainer")


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
		pin.is_tracked = true
		
		var signal_line = Line2D.new()
		signal_line.add_point(Vector2(0, SIGNAL_ROW_HEIGHT*0.9))
		signal_line.default_color = SIGNAL_COLORS[color_index % SIGNAL_COLORS.size()]
		color_index += 1
		signal_line.width = 2
		signal_container.add_child(signal_line)
		
		var sig = LA_Signal.new(
			line_edit,
			signal_line,
			pin.parent.id, 
			pin.index
			)
		signals.append(sig)
		line_edit_menu.add_item("Прекратить отслеживание", 2281337)
		line_edit_menu.id_pressed.connect(
			func(id): 
				if (id == 2281337):
					remove_signal(sig, pin)
		)
		clear_signal_values()
	
func _on_text_submitted(text, id):
	pass


func _process(delta: float) -> void:
	if (start_stop_analysis_button.is_analysis_in_progress):
		var current_signal_index = 0
		for sig in signals:
			draw_new_signal_value(sig, current_signal_index, delta)
			current_signal_index += 1

func draw_new_signal_value(sig: LA_Signal, signal_index: int, time_delta: float):
	var line = sig.signal_line
	var points = line.points
	var prev_point = points[points.size()-1]
	
	var val = get_current_signal_value(sig)
	
	line.position.y = SIGNAL_ROW_HEIGHT * signal_index
	
	var new_point_x = prev_point.x + signal_values_zoom_factor * time_delta * 100
	
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
	
	# Always show latest value drawn
	get_tree().create_timer(.01).timeout.connect(
		func():
			scroll_container.scroll_horizontal = scroll_container.get_h_scroll_bar().max_value
	)


func get_current_signal_value(sig: LA_Signal) -> NetConstants.LEVEL:
	for i: Pin in NetlistClass.nodes.keys():
		if i.index == sig.pin_index && i.parent.id == sig.ic_id:
			return i.state
	push_error("Logic Analyzer couldn't find Pin " + str(sig) + " in the netlist")
	return NetConstants.LEVEL.LEVEL_Z # Pin is inexistent


func remove_signal(sig_to_del: LA_Signal, pin: Pin):
	if is_instance_valid(pin):
		pin.modulate = Color(1, 1, 1, 1)
		pin.toggle_output_highlight()
		pin.is_tracked = false
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
		line.add_point(Vector2(0, SIGNAL_ROW_HEIGHT*0.9))
	scroll_container.scroll_horizontal = 0
	signal_container.custom_minimum_size.x = 0


func set_signal_values_zoom_factor(factor: float):
	var new_zoom_ratio = factor / signal_values_zoom_factor
	signal_values_zoom_factor = factor
	for sig in signals: 
		var line = sig.signal_line
		var points_before = line.points
		line.clear_points()
		line.add_point(points_before[0])
		for point_before in points_before.slice(1):
			var new_point_x = point_before.x * new_zoom_ratio
			
			signal_container.custom_minimum_size.x = new_point_x
			
			line.add_point(Vector2(new_point_x, point_before.y))
			
			# Always show latest value drawn
			get_tree().create_timer(.01).timeout.connect(
				func():
					scroll_container.scroll_horizontal = scroll_container.get_h_scroll_bar().max_value
			)
	


func _on_zoom_out_button_pressed() -> void:
	signal_values_zoom_factor = signal_values_zoom_factor * 3 / 4


func _on_zoom_in_button_pressed() -> void:
	signal_values_zoom_factor = signal_values_zoom_factor * 4 / 3
