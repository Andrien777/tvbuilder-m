extends Control

class_name LASignalGroupLine

const Radix = preload("res://ui/logic_analyzer/Radix.gd").Radix

var zoom_factor: float
var sig_group: LASignalGroup
var height: float

func _init(
	zoom_factor: float,
	sig_group: LASignalGroup,
	height: float
):
	self.zoom_factor = zoom_factor
	self.sig_group = sig_group
	self.height = height


func _draw():
	var font = get_theme_default_font()
	var font_size = get_theme_default_font_size()
	
	var current_indexes: Array[int] = []
	var current_time = 0
	current_indexes.resize(sig_group.signals.size())
	current_indexes.fill(0)
	
	var sizes_minus_one = sig_group.signals.map(
		func(sig): 
			return sig.signal_points.size()
	)
	
	var value_binary = "0".repeat(sig_group.signals.size())
	var points = [] # Array of [time in ms, value] 
	while current_indexes != sizes_minus_one:
		var closest_edge = [1 << 63 - 1, null]
		var closest_edge_time_sig_ind = -1
		for sig_ind in range(sig_group.signals.size()):
			if sig_group.signals[sig_ind].signal_points.size() > current_indexes[sig_ind]:
				var edge = sig_group.signals[sig_ind].signal_points[current_indexes[sig_ind]]
				if edge[0] < closest_edge[0]:
					closest_edge = edge
					closest_edge_time_sig_ind = sig_ind
		
		value_binary[closest_edge_time_sig_ind] = str(closest_edge[1])
		var value_binary_reversed = value_binary.reverse()
		var value = binary_to_radix(value_binary_reversed, sig_group.radix)
		
		current_indexes[closest_edge_time_sig_ind] += 1
		current_time = closest_edge[0]
		
		if points.size() > 0 and points[-1][0] == current_time:
			points.back()[1] = value
		else:
			points.append([current_time, value])
	
	var compressed_points = []
	for point in points:
		if compressed_points.size() == 0 or compressed_points[-1][1] != point[1]:
			compressed_points.append(point)
	
	for point_ind in range(compressed_points.size()):
		var point = compressed_points[point_ind]
		var value = point[1]
		var text_size = font.get_string_size(value, font_size)
		var start = Vector2(point[0] * zoom_factor, height / 2 + 5)
		var end_x: float
		if point_ind + 1 < compressed_points.size():
			end_x = compressed_points[point_ind+1][0] * zoom_factor
		else:
			end_x = points[-1][0] * zoom_factor
		var width = end_x - start.x
		if (width > 0.0):
			# Outline for value
			draw_polyline(
				PackedVector2Array([
					Vector2(start.x+3, height*.8),
					Vector2(end_x-3, height*.8),
					Vector2(end_x, height/2),
					Vector2(end_x-3, height*.2),
					Vector2(start.x+3, height*.2),
					Vector2(start.x, height/2),
					Vector2(start.x+3, height*.8)
				]),
				Color.GHOST_WHITE
			)
			draw_string(font, start, value, HORIZONTAL_ALIGNMENT_CENTER, width, font_size)


func binary_to_radix(value_binary: String, radix: Radix) -> String:
	var value = ""
	if radix == Radix.BINARY_DECIMAL:
		var binary_reversed = value_binary
		binary_reversed.reverse()
		var i = 0
		while i < binary_reversed.length():
			var digit = binary_reversed.substr(i, 4)
			digit += "0".repeat(4 - digit.length())
			value += str(digit.bin_to_int())
			i += 4
	elif radix == Radix.BINARY:
		value = value_binary
	else:
		value = str(String.num_int64(value_binary.bin_to_int(), radix, true))
	return value
