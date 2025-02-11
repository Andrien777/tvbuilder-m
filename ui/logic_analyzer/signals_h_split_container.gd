extends HSplitContainer

const SIGNAL_ROW_HEIGHT = 70
const SIGNAL_COLORS: Array[Color] = [
	Color(1,1,1),
	Color(0.16862746, 0.5254902, 0.8784314),
	Color(0.820, 0.097, 0.060),
	Color(0.7764706, 0.7019608, 0.13333334),
	Color(0.0, 0.8117647, 0.32156864),
	Color(0.45490196, 0.22352941, 0.92941177),
	Color(0.994, 0.561, 0.907),
	Color(0.011764706, 1.0, 0.6431373),
]
var color_index = 0
var signals: Array[LA_Signal]
var signal_values_zoom_factor: float = 1.0:
	set = set_signal_values_zoom_factor
var is_analysis_in_progress = false

@onready var select_pins_button = get_node("/root/RootNode/LogicAnalyzerWindow/RootVBoxContainer/ButtonHBoxContainer/SelectPinsButton")
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

func _ready() -> void:
	NetlistClass.scheme_processed.connect(draw_new_signal_values)

func add_signal(pin: Pin):
	if select_pins_button.is_add_pins_mode_on:
		var line_edit = LineEdit.new()
		line_edit.custom_minimum_size = Vector2(0, SIGNAL_ROW_HEIGHT - 4)
		line_edit.size.y = SIGNAL_ROW_HEIGHT - 4
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
		
		# Remove useless menu items
		for item_index in [15,14,13,12,11,10]:
			line_edit_menu.remove_item(item_index)
		line_edit_menu.add_item("Прекратить отслеживание", 2281337)
		line_edit_menu.always_on_top = GlobalSettings.is_LA_always_on_top
		line_edit_menu.close_requested.connect(
			func():
				line_edit_menu.always_on_top = false
		) # It crashes out when closing LogicAnalyzerWindow wihtout that line
		

		line_edit_menu.index_pressed.connect(
			func(index): 
				print(index)
				if (line_edit_menu.get_item_id(index) == 2281337):
					remove_signal(sig)
		)
		clear_signal_values()


var last_propagation_time = 0
func draw_new_signal_values(forced_generator: bool = false) -> void:
	if is_analysis_in_progress || forced_generator:
		var current_time = Time.get_unix_time_from_system()
		var propagation_time_delta: float
		if forced_generator:
			propagation_time_delta = 0.1
		elif last_propagation_time == 0:
			propagation_time_delta = 0
		else:
			propagation_time_delta = current_time - last_propagation_time 
		last_propagation_time = current_time
		var current_signal_index = 0
		for sig in signals:
			draw_new_signal_value(sig, current_signal_index, propagation_time_delta)
			current_signal_index += 1
	elif !is_analysis_in_progress:
		last_propagation_time = 0

func draw_new_signal_value(sig: LA_Signal, signal_index: int, time_delta: float):
	var line = sig.signal_line
	var points = line.points
	var prev_point = points[points.size()-1]
	
	var val = get_current_signal_value(sig)
	var name: String
	
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
	var ic = ComponentManager.get_by_id(sig.ic_id)
	if is_instance_valid(ic) and ic != null:
		return ic.pin(sig.pin_index).state
	push_error("Logic Analyzer couldn't find Pin " + str(sig) + " in the netlist")
	return NetConstants.LEVEL.LEVEL_Z # Pin is inexistent


func remove_signal(sig_to_del: LA_Signal):
	var pin = ComponentManager.get_by_id(sig_to_del.ic_id).pin(sig_to_del.pin_index)
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


func simulate(time_ms: float):
	clear_signal_values()
	var generator = find_generator()
	if generator == null:
		#PopupManager.display_error(
			#"Отсутсвует генератор", 
			#"Для симуляции необходимо иметь генератор", 
			#get_global_mouse_position()
			#)
		InfoManager.write_error("Отсутствет генератор. Для проведения симуляции необходимо наличие генератора в схеме")
		return
	var was_generator_enabled = generator.enabled
	generator.enabled = false
	GlobalSettings.disableGlobalInput = true
	
	var generator_freq_text = generator.text_line.text
	var freq_hz = .0
	if generator_freq_text.is_valid_float():
		freq_hz = float(generator_freq_text)
		
	var clock_cycles: float = time_ms * .001 * freq_hz
	var clock_cycle_time = time_ms / clock_cycles
	draw_new_signal_values(true)
	
	for i in range(clock_cycles*2-1):
		if generator.pin(1).high:
			generator.pin(1).set_low()
			generator.pin(2).set_high()
		else:
			generator.pin(1).set_high()
			generator.pin(2).set_low()
		NetlistClass.process_scheme()
		draw_new_signal_values(true)
	
	last_propagation_time = 0
	generator.enabled = was_generator_enabled
	GlobalSettings.disableGlobalInput = false


func find_generator() -> FrequencyGenerator:
	for pin: Pin in NetlistClass.nodes.keys():
		if pin.parent is FrequencyGenerator:
			return pin.parent
	return null
