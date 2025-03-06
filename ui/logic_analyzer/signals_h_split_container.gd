extends HSplitContainer

signal zoom_changed(new_zoom: float)

const Radix = preload("res://ui/logic_analyzer/Radix.gd").Radix

const SIGNAL_ROW_HEIGHT = 55
const SIGNAL_COLORS: Array[Color] = [
	Color(1,1,1),
	Color(0.16862746, 0.85490197, 0.8784314),
	Color(0.8745098, 0.3529412, 0.31764707),
	Color(0.91764706, 0.85490197, 0.3529412),
	Color(0.6392157, 0.94509804, 0.7490196),
	Color(0.73333335, 0.6666667, 0.8666667),
	Color(0.994, 0.561, 0.907),
	Color(0.011764706, 1.0, 0.6431373),
]
var color_index = 0
var signals: Array # Of either LA_signal or LA_signal_group
var signal_values_zoom_factor: float: # Pixels per ms
	set = set_signal_values_zoom_factor
var is_analysis_in_progress = false

@onready var time_line = get_node("../../GroupButtonTimeLineContainer/TimeLine")
@onready var simulation_progress_bar: ProgressBar = get_node("../../SimulationProgressContainer/SimulationProgressBar")
@onready var simulation_progress_container: Container = get_node("../../SimulationProgressContainer")
@onready var cancel_simulation_button: Button = get_node("../../SimulationProgressContainer/CancelSimulationButton")
@onready var select_pins_button = get_node("../../ButtonHBoxContainer/SelectPinsButton")
@onready var signals_container = get_node("./SignalsPanelContainer/SignalsScrollContainer/SignalsVBoxContainer")
@onready var scroll_container = get_node("./SignalsPanelContainer/SignalsScrollContainer")
@onready var labels_container = get_node("./SignalLabelsPanelContainer/SignalLabelsVBoxContainer")


func _ready() -> void:
	signal_values_zoom_factor = 0.1
	NetlistClass.scheme_processed.connect(process_analysis_tick)


func add_signal(pin: Pin):
	if select_pins_button.is_add_pins_mode_on:
		pin.is_tracked = true
		var signal_controller = LASignalController.new(
			pin.readable_name,
			SIGNAL_ROW_HEIGHT
			)
		var sig = LASignal.new(
			signal_controller,
			signal_values_zoom_factor,
			SIGNAL_COLORS[color_index % SIGNAL_COLORS.size()],
			SIGNAL_ROW_HEIGHT,
			pin.parent.id,
			pin.index,
			)
		color_index += 1
		signals.append(sig)

		signal_controller.sig_remove_requested.connect(
			func():
				remove_signal(sig)
		)
		zoom_changed.connect(
			func(new_factor: float):
				if is_instance_valid(sig) and is_instance_valid(sig.signal_line):
					sig.signal_line.zoom_factor = new_factor
					sig.signal_line.queue_redraw()
		)
		
		clear_signal_values()
		redraw()


func add_group(signals_to_group: Array):
	var group_name: String = " ".join(
		PackedStringArray(signals_to_group.map(
			func(sig):
				return sig.signal_controller.line_edit.text)
		)
	)

	var group_controller = LASignalGroupController.new(
		group_name, SIGNAL_ROW_HEIGHT
	)
	
	group_controller.show_signals_changed.connect(
		func(_show_signals):
			redraw()
	)
			
	var group = LASignalGroup.new(
		group_controller, signals_to_group, signal_values_zoom_factor, SIGNAL_ROW_HEIGHT, Radix.BINARY
	)
	for sig in signals_to_group:
		signals.erase(sig)
	signals.append(group)
	signals_container.add_child(group.signal_line)
	
	zoom_changed.connect(
		func(new_factor: float):
			if is_instance_valid(group) and is_instance_valid(group.signal_line):
				group.signal_line.zoom_factor = new_factor
				group.signal_line.queue_redraw()
	)

	clear_signal_values()
	redraw()


func redraw():
	for child in labels_container.get_children():
		labels_container.remove_child(child)
	for child in signals_container.get_children():
		signals_container.remove_child(child)
	for sig_ind in range(signals.size()):
		var sig = signals[sig_ind]
		if sig is LASignal:
			remove_connections(sig.signal_controller.button_up.button_up)
			remove_connections(sig.signal_controller.button_down.button_up)
			if sig_ind < signals.size()-1:
				sig.signal_controller.button_down.button_up.connect(
					func():
						var temp = signals[sig_ind]
						signals[sig_ind] = signals[sig_ind+1]
						signals[sig_ind+1] = temp
						redraw()
				)
			if sig_ind > 0:
				sig.signal_controller.button_up.button_up.connect(
					func():
						var temp = signals[sig_ind]
						signals[sig_ind] = signals[sig_ind-1]
						signals[sig_ind-1] = temp
						redraw()
				)
			labels_container.add_child(sig.signal_controller)
			#print(sig.signal_line.get_parent())
			signals_container.add_child(sig.signal_line)
		
		elif sig is LASignalGroup:
			labels_container.add_child(sig.group_controller)
			signals_container.add_child(sig.signal_line)
			
			remove_connections(sig.group_controller.button_up.button_up)
			remove_connections(sig.group_controller.button_down.button_up)
			if sig_ind < signals.size()-1:
				sig.group_controller.button_down.button_up.connect(
					func():
						var temp = signals[sig_ind]
						signals[sig_ind] = signals[sig_ind+1]
						signals[sig_ind+1] = temp
						redraw()
				)
			if sig_ind > 0:
				sig.group_controller.button_up.button_up.connect(
					func():
						var temp = signals[sig_ind]
						signals[sig_ind] = signals[sig_ind-1]
						signals[sig_ind-1] = temp
						redraw()
				)
				
			for sig_ind_ in range(sig.signals.size()):
				var sig_ = sig.signals[sig_ind_] as LASignal
				remove_connections(sig_.signal_controller.button_up.button_up)
				remove_connections(sig_.signal_controller.button_down.button_up)
				if sig_ind_ < sig.signals.size()-1:
					sig_.signal_controller.button_down.button_up.connect(
						func():
							var temp = sig.signals[sig_ind_]
							sig.signals[sig_ind_] = sig.signals[sig_ind_+1]
							sig.signals[sig_ind_+1] = temp
							redraw()
					)
				if sig_ind_ > 0:
					sig_.signal_controller.button_up.button_up.connect(
						func():
							var temp = sig.signals[sig_ind_]
							sig.signals[sig_ind_] = sig.signals[sig_ind_-1]
							sig.signals[sig_ind_-1] = temp
							redraw()
					)
					
			for sig_ in sig.signals:
				var parent = sig_.signal_controller.get_parent() as Node
				if parent != null:
					for child in parent.get_children():
						if child is LASignalController:
							parent.remove_child(child)
					parent.queue_free()
					
			if sig.group_controller.show_signals:
				for sig_ in sig.signals:
					var signal_controller_wrapper = HBoxContainer.new()
					var spacer = Control.new()
					spacer.size.x = 20
					spacer.custom_minimum_size.x = 20
					signal_controller_wrapper.add_child(spacer)
					sig_.signal_controller.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					signal_controller_wrapper.add_child(sig_.signal_controller)
					labels_container.add_child(signal_controller_wrapper)
					signals_container.add_child(sig_.signal_line)
				
			remove_connections(sig.group_controller.ungroup_requested)
			sig.group_controller.ungroup_requested.connect(
				func():
					if sig != null:
						signals.erase(sig)
						
						for sig_ in sig.signals:
							var parent = sig_.signal_controller.get_parent() as Node
							if parent != null:
								for child in parent.get_children():
									if child is LASignalController:
										parent.remove_child(child)
							signals.append(sig_)
						sig.queue_free()
						redraw()
			)


var tick_n = 0
func process_analysis_tick() -> void:
	tick_n += 1
	var tick_time = 1000.0 / Engine.physics_ticks_per_second
	if (GlobalSettings.turbo):
		tick_time /= 3
	var current_analysis_time = tick_time*tick_n
	if is_analysis_in_progress:
		for sig in signals:
			if sig is LASignal:
				update_with_current_value(sig, current_analysis_time)
			elif sig is LASignalGroup:
				for sig_ in sig.signals:
					update_with_current_value(sig_, current_analysis_time)
			
		draw_graphs()
		# Always show latest value drawn
		get_tree().create_timer(.01).timeout.connect(
			func():
				scroll_container.scroll_horizontal = scroll_container.get_h_scroll_bar().max_value
		)
	elif !is_analysis_in_progress:
		tick_n = 0


func update_with_current_value(sig: LASignal, time: float):
	var value = get_current_signal_value(sig)
	# Pop non-edge values
	if (sig.signal_points.size() > 2
		&& sig.signal_points[-1][1] == value
		&& sig.signal_points[-2][1] == value):
		sig.signal_points.pop_back()
		
	sig.signal_points.append(
		[time, value]
	)


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
	
	for i in range(clock_cycles*2+1):
		if _simulation_canceled:
			break
		for sig in signals:
			if sig is LASignal:
				var current_signal_value = get_current_signal_value(sig)
				sig.signal_points.append(
					[(clock_cycle_time * i) / 2, current_signal_value]
				)
			elif sig is LASignalGroup:
				for sig_ in sig.signals:
					var current_signal_value = get_current_signal_value(sig_)
					sig_.signal_points.append(
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
		
	draw_graphs()
	# Make all values fit into 1000 px
	signal_values_zoom_factor = 1000/time_ms
	
	simulation_progress_container.visible = false
	generator.enabled = was_generator_enabled
	GlobalSettings.disableGlobalInput = false


func get_current_signal_value(sig: LASignal) -> NetConstants.LEVEL:
	return _get_current_signal_value(sig.ic_id, sig.pin_index)


func _get_current_signal_value(ic_id: int, pin_index: int) -> NetConstants.LEVEL:
	var ic = ComponentManager.get_by_id(ic_id)
	if is_instance_valid(ic) and ic != null:
		return ic.pin(pin_index).state
	push_error("Logic Analyzer couldn't find Pin with ic_id=" + str(ic_id) + ", pin_index=" + str(pin_index) + " in the netlist")
	return NetConstants.LEVEL.LEVEL_Z # Pin is inexistent


func remove_signal(sig_to_del: LASignal):
	var pin = ComponentManager.get_by_id(sig_to_del.ic_id).pin(sig_to_del.pin_index)
	if is_instance_valid(pin):
		pin.modulate = Color(1, 1, 1, 1)
		pin.toggle_output_highlight()
		pin.is_tracked = false
	signals.erase(sig_to_del)
	for sig in signals:
		if sig is LASignalGroup:
			sig.signals.erase(sig_to_del)
			
	sig_to_del.signal_controller.queue_free()
	sig_to_del.signal_line.queue_free()


func clear_signal_values():
	for sig in signals:
		if sig is LASignal:
			sig.signal_points.clear()
			sig.signal_line.queue_redraw()
		elif sig is LASignalGroup:
			for sig_ in sig.signals:
				sig_.signal_points.clear()
				sig_.signal_line.queue_redraw()
			sig.signal_line.queue_redraw()

	scroll_container.scroll_horizontal = 0
	signals_container.custom_minimum_size.x = 0


func set_signal_values_zoom_factor(new_factor: float):
	signal_values_zoom_factor = new_factor
	
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
	
	zoom_changed.emit(new_factor)
	
	draw_graphs()


func _on_zoom_out_button_pressed() -> void:
	signal_values_zoom_factor = signal_values_zoom_factor * 3 / 4


func _on_zoom_in_button_pressed() -> void:
	signal_values_zoom_factor = signal_values_zoom_factor * 4 / 3


func draw_graphs():
	for signal_index in range(signals.size()):
		var sig = signals[signal_index]
		if sig is LASignal:
			sig.signal_line.queue_redraw()
		elif sig is LASignalGroup:
			sig.signal_line.queue_redraw()
	if signals.size() > 0:
		var end_time: float
		for sig in signals:
			if sig is LASignal:
				end_time = max(end_time, sig.signal_points[-1][0])
			elif sig is LASignalGroup:
				for sig_ in sig.signals:
					if sig_.signal_points.size() > 0:
						end_time = max(end_time, sig_.signal_points[-1][0])
		signals_container.custom_minimum_size.x = end_time*signal_values_zoom_factor


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
		
static func remove_connections(sig: Signal):
	for conn in sig.get_connections():
		sig.disconnect(conn.callable)
