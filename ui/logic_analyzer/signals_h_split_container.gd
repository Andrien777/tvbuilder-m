extends HSplitContainer

signal zoom_changed()

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
var simulation_end_time: float = 0
var signal_values_zoom_factor: float: # Pixels per ms
	set = set_signal_values_zoom_factor
var is_analysis_in_progress = false

@onready var time_line = get_node("../../TimeLine")
@onready var simulation_progress_bar: ProgressBar = get_node("../../SimulationProgressContainer/SimulationProgressBar")
@onready var simulation_progress_container: Container = get_node("../../SimulationProgressContainer")
@onready var cancel_simulation_button: Button = get_node("../../SimulationProgressContainer/CancelSimulationButton")
@onready var select_pins_button = get_node("../../ButtonHBoxContainer/SelectPinsButton")
@onready var signal_container = get_node("./SignalsPanelContainer/SignalsScrollContainer/SignalsVBoxContainer")
@onready var scroll_container = get_node("./SignalsPanelContainer/SignalsScrollContainer")
@onready var label_container = get_node("./SignalLabelsPanelContainer/SignalLabelsVBoxContainer")

class LA_Signal:
	var line_edit: LineEdit
	var signal_line: Line2D

	var signal_points: Array[Array] = []  # Array of pairs time(ms) to level [float, NetConstants.LEVEL]
		
	var ic_id: int
	var pin_index: int
	
	func _init(
		line_edit: LineEdit,
		signal_line: Line2D,
		ic_id: int,
		pin_index: int,
	):
		self.line_edit = line_edit
		self.signal_line = signal_line
		self.ic_id = ic_id
		self.pin_index = pin_index
	
	func _to_string() -> String:
		return "Parent ic's id = " + str(ic_id) + "; Pin_index = " + str(pin_index)	
		
		
func _ready() -> void:
	signal_values_zoom_factor = 0.1
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
			pin.index,
			)
		signals.append(sig)
		
		# Remove useless menu items
		for item_index in [15,14,13,12,11,10]:
			line_edit_menu.remove_item(item_index)
		line_edit_menu.add_item("Прекратить отслеживание", 2281337)

		line_edit_menu.index_pressed.connect(
			func(index):
				if (line_edit_menu.get_item_id(index) == 2281337):
					remove_signal(sig)
		)
		clear_signal_values()

var analysis_start_time = 0
func draw_new_signal_values() -> void:
	if is_analysis_in_progress:
		var time = Time.get_unix_time_from_system()
		if analysis_start_time == 0: 
			analysis_start_time = time
		for sig in signals:
			var value = get_current_signal_value(sig)
			# Pop non-edge values
			if (sig.signal_points.size() > 2 
				&& sig.signal_points[-1][1] == value 
				&& sig.signal_points[-2][1] == value):
				sig.signal_points.pop_back()
				
			sig.signal_points.append( 
				[(time - analysis_start_time)*1000, value]
			)
			sig.signal_line.clear_points()
		draw_graphs((time - analysis_start_time)*1000)
		# Always show latest value drawn
		get_tree().create_timer(.01).timeout.connect(
			func():
				scroll_container.scroll_horizontal = scroll_container.get_h_scroll_bar().max_value
		)
	elif !is_analysis_in_progress:
		analysis_start_time = 0

var _simulation_canceled = false
func simulate(time_ms: float):
	clear_signal_values()
	
	var generator = find_generator()
	if generator == null:
		InfoManager.write_error("Отсутствет генератор. Для проведения симуляции необходимо наличие генератора в схеме")
		return
	var was_generator_enabled = generator.enabled
	generator.enabled = false
	GlobalSettings.disableGlobalInput = true
	
	_simulation_canceled = false
	cancel_simulation_button.button_up.connect(
		func():
			_simulation_canceled = true
	)
	simulation_progress_container.visible = true
	simulation_progress_bar.value = .0
	
	var generator_freq_text = generator.text_line.text
	var freq_hz = .0
	if generator_freq_text.is_valid_float():
		freq_hz = float(generator_freq_text)
		
	var clock_cycles: float = time_ms * .001 * freq_hz
	var clock_cycle_time = time_ms / clock_cycles
	
	for i in range(clock_cycles*2):
		if _simulation_canceled: 
			break
		for sig in signals:
			var current_signal_value = get_current_signal_value(sig)
			sig.signal_points.append( 
				[(clock_cycle_time * i) / 2, current_signal_value]
			)
		if generator.pin(1).high:
			generator.pin(1).set_low()
			generator.pin(2).set_high()
		else:
			generator.pin(1).set_high()
			generator.pin(2).set_low()
		NetlistClass.process_scheme()
			
		var prev_value = simulation_progress_bar.value
		simulation_progress_bar.value = (i+1) / (clock_cycles*2) * 100
		if int(simulation_progress_bar.value) > int(prev_value):
			await get_tree().process_frame
		
	draw_graphs(time_ms)
	# Make all values fit into 1000 px
	signal_values_zoom_factor = 1000/time_ms
	
	simulation_progress_container.visible = false
	generator.enabled = was_generator_enabled
	GlobalSettings.disableGlobalInput = false

func get_current_signal_value(sig: LA_Signal) -> NetConstants.LEVEL:
	return _get_current_signal_value(sig.ic_id, sig.pin_index)

func _get_current_signal_value(ic_id: int, pin_index: int) -> NetConstants.LEVEL:
	var ic = ComponentManager.get_by_id(ic_id)
	if is_instance_valid(ic) and ic != null:
		return ic.pin(pin_index).state
	push_error("Logic Analyzer couldn't find Pin with ic_id=" + str(ic_id) + ", pin_index=" + str(pin_index) + " in the netlist")
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
	for ind in range(signals.size()): 
		signals[ind].signal_line.position.y = SIGNAL_ROW_HEIGHT * ind


func clear_signal_values():
	for sig in signals:
		var line = sig.signal_line
		line.clear_points()
		sig.signal_points = []
		line.add_point(Vector2(0, SIGNAL_ROW_HEIGHT*0.9))
	scroll_container.scroll_horizontal = 0
	signal_container.custom_minimum_size.x = 0


func set_signal_values_zoom_factor(new_factor: float):
	signal_values_zoom_factor = new_factor
	var end_time = 0
	for sig in signals: 
		end_time = max(end_time, sig.signal_points.back()[0])
		sig.signal_line.clear_points()
	draw_graphs(end_time)
	
	var time_units = [
		["фс", 1e-15],
		["пс", 1e-12],
		["нс", 1e-9],
		["мкс", 1e-6],
		["мс", 1e-3],
		["с", 1e0],
		["кс", 1e3]
		]
		
	var best_time_unit 
	var best_delta_time
	var best_delta_px = 1 << 63 - 1
	for time_unit in time_units:
		for delta_time in [10, 20, 40, 100, 200, 400, 1000, 2000, 4000]:
			var delta_px = delta_time*time_unit[1]*1000 * new_factor
			# Search for delta_px closest to 150px
			if abs(delta_px - 150) < abs(best_delta_px - 150):
				best_time_unit = time_unit
				best_delta_time = delta_time
				best_delta_px = delta_px
	
	time_line.delta_px = best_delta_px
	time_line.delta_time = best_delta_time
	time_line.time_unit = best_time_unit[0]
	
	zoom_changed.emit()


func _on_zoom_out_button_pressed() -> void:
	signal_values_zoom_factor = signal_values_zoom_factor * 3 / 4


func _on_zoom_in_button_pressed() -> void:
	signal_values_zoom_factor = signal_values_zoom_factor * 4 / 3


func draw_graphs(end_time: float):
	for signal_index in range(signals.size()):
		var sig = signals[signal_index]
		var signal_line = sig.signal_line
		var start_y = level_to_height(sig.signal_points[0][1])
		
		signal_line.add_point(Vector2(0, start_y))
		signal_line.position.y = SIGNAL_ROW_HEIGHT * signal_index
		
		for ind in range(1, sig.signal_points.size()):
			var point = sig.signal_points[ind]
			var time = point[0]
			var value = point[1]
			
			var prev_point = sig.signal_points[ind-1]
			var prev_time = prev_point[0]
			var prev_value = prev_point[1]
			
			var x = time*signal_values_zoom_factor
			var new_point_y = level_to_height(value)
			var prev_point_y = level_to_height(prev_value)
			signal_line.add_point(Vector2(x, prev_point_y))
			signal_line.add_point(Vector2(x, new_point_y))

		var end_x = end_time*signal_values_zoom_factor
		var end_y = level_to_height(sig.signal_points[-1][1])
		signal_line.add_point(Vector2(end_x, end_y))
		signal_container.custom_minimum_size.x = end_x
	
func level_to_height(level: NetConstants.LEVEL): 
	return (.1 if level == NetConstants.LEVEL.LEVEL_HIGH else .9) * SIGNAL_ROW_HEIGHT

func find_generator() -> FrequencyGenerator:
	for pin: Pin in NetlistClass.nodes.keys():
		if pin.parent is FrequencyGenerator:
			return pin.parent
	return null
	
	
@onready var cursor_line: Line2D = get_node("./SignalsPanelContainer/Cursor")
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		cursor_line.global_position = Vector2(get_global_mouse_position().x, cursor_line.global_position.y)
		
