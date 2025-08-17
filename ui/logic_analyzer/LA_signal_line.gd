extends Control


class_name LASignalLine

var zoom_factor: float
var color: Color
var height: float
var sig: LASignal


func _init(
	sig: LASignal,
	zoom_factor: float,
	color: Color,
	height: float,
):
	self.zoom_factor = zoom_factor
	self.color = color
	self.sig = sig
	self.height = height
	custom_minimum_size.y = height
	size.y = height


func _draw():
	var font = get_theme_default_font()
	var font_size = get_theme_default_font_size()
	
	for ind in range(1, sig.signal_points.size()):
		var point = sig.signal_points[ind]
		var time = point[0]
		var value = point[1]
		
		var prev_point = sig.signal_points[ind-1]
		var prev_time = prev_point[0]
		var prev_value = prev_point[1]
		
		var x = time*zoom_factor
		var prev_x = prev_time*zoom_factor
		
		if prev_value == NetConstants.LEVEL.LEVEL_Z:
			draw_line(Vector2(prev_x, 0.5 * height), Vector2(x, 0.5 * height), color, 5)
		elif prev_value == NetConstants.LEVEL.PIN_INEXISTENT:
			draw_string(font, Vector2(prev_x, 0.5*height + 5), "X", HORIZONTAL_ALIGNMENT_CENTER, x-prev_x, font_size)
		else:
			var new_y = level_to_height(value)
			var prev_y = level_to_height(prev_value)
			
			draw_line(
				Vector2(prev_x-.5, prev_y),
				Vector2(x+.5, prev_y),
				color,
				3 if (prev_value == NetConstants.LEVEL.LEVEL_HIGH) else 1
			)
			draw_line(Vector2(x, prev_y), Vector2(x, new_y), color, 1)
		# Separation line
		if !sig.signal_points.is_empty():
			draw_line(Vector2(0, height), Vector2(1e10, height), Color.LIGHT_GRAY)


func level_to_height(level: NetConstants.LEVEL): 
	return (.1 if level == NetConstants.LEVEL.LEVEL_HIGH else .9) * height
