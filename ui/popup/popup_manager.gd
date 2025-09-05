extends Node
var canvas_layer
var pin_popup
var error_popup
var timer = Timer.new()
func _init()->void:
	
	canvas_layer = CanvasLayer.new()
	pin_popup = HintPopup.new()
	#pin_popup.global_position = Vector2(0,0)
	pin_popup.z_index = 5
	pin_popup.visible=false
	pin_popup.modulate = Color(1,1,1,0)
	error_popup = HintPopup.new()
	error_popup.z_index = 5
	error_popup.visible=false
	error_popup.modulate = Color(1,0.8,0.8,0)
	canvas_layer.add_child(error_popup)
	canvas_layer.add_child(pin_popup)
	canvas_layer.follow_viewport_enabled = true
	canvas_layer.follow_viewport_scale = 1.0
	timer.timeout.connect(error_popup.hide_popup)
	add_child(timer)
	#canvas_layer.offset = Vector2(500,500)
	#canvas_layer.follow_viewport_scale = false
	add_child(canvas_layer)
	#add_child(pin_popup)
	
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func display_hint(heading:String, description:String, position:Vector2, direction:NetConstants.DIRECTION, pin: Pin):
	pin_popup.visible=true
	var popup_color = Color(1,1,1,0.9)
	match(direction):
		NetConstants.DIRECTION.DIRECTION_INPUT:
			popup_color = Color(1,0.8,1,0.9)
		NetConstants.DIRECTION.DIRECTION_OUTPUT:
			popup_color = Color(1,1,0.8,0.9)
	pin_popup.display(heading, description, position, popup_color, pin)

func hide_hint():
	pin_popup.hide_popup()
	
var last_error_position = Vector2(0,0)

func display_error(heading:String, description:String, position:Vector2):
	timer.stop()
	timer.wait_time = 0.6 
	timer.one_shot = false
	timer.start() 
	
	if(position!=last_error_position or error_popup.modulate[3]<0.1): # If the popup has moved or is invisible
		
		#error_popup.position = position
		if position!=last_error_position:
			InfoManager.write_error(heading +' :: '+ description)
		error_popup.visible=true
		error_popup.display(heading, description, position, Color(1,0.8,0.8,0.9))
		last_error_position = position
