extends Control

@onready var signals_scroll_container = %SignalsScrollContainer as ScrollContainer
@onready var signals_container = %SignalsHSplitContainer

var _scrolled = 0.0:
	set = set_scrolled
func set_scrolled(value):
	_scrolled = value
	queue_redraw()
	
var delta_time = 1000.0:
	set = set_delta_time
func set_delta_time(value):
	delta_time = value
	queue_redraw()
	
var delta_px = 100:
	set = set_delta_px
func set_delta_px(value):
	delta_px = value
	queue_redraw()
	
var time_unit: String = "мс":
	set = set_time_unit
func set_time_unit(value):
	time_unit = value
	queue_redraw()

func _ready():
	custom_minimum_size.y = 20
	
	resized.connect(queue_redraw)
	
	signals_container.drag_ended.connect(queue_redraw)
	
	signals_scroll_container.get_h_scroll_bar().scrolling.connect(
		func():
			_scrolled = signals_scroll_container.scroll_horizontal
	)
	
	signals_scroll_container.get_h_scroll_bar().changed.connect(
		func():
			_scrolled = signals_scroll_container.scroll_horizontal
	)
	
	
func _draw():
	var split_offset = 10
	var center_y = size.y / 2
	var current_offset = split_offset + fposmod(delta_px - _scrolled, delta_px)
	var current_time = ceil(_scrolled / delta_px) * delta_time
	
	var ticks_count = ceil(size.x / delta_px) # More points won't be needed
	for i in range(ticks_count): 
		# Vertical tick mark
		draw_line(Vector2(current_offset, size.y+4), Vector2(current_offset, size.y-6), Color.WHITE, 2)
		
		# Time label
		var time_text = "%d" % current_time + time_unit
		var font = get_theme_default_font()
		var font_size = get_theme_default_font_size()
		if font != null:
			var text_size = font.get_string_size(time_text, font_size)
			var text_pos = Vector2(current_offset - text_size.x / 2, center_y + 2)
			draw_string(font, text_pos, time_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			
		current_offset += delta_px
		current_time += delta_time


func _on_signals_h_split_container_zoom_changed(_new_zoom: float) -> void:
	get_tree().create_timer(0.01).timeout.connect(
		func():
			_scrolled = signals_scroll_container.scroll_horizontal
	)
	queue_redraw()
