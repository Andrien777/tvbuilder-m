extends Node
var canvas_layer
var pin_popup
func _init()->void:
	canvas_layer = CanvasLayer.new()
	pin_popup = HintPopup.new()
	#pin_popup.global_position = Vector2(0,0)
	pin_popup.z_index = 5
	pin_popup.visible=false
	pin_popup.modulate = Color(1,1,1,0)
	canvas_layer.add_child(pin_popup)
	canvas_layer.follow_viewport_enabled = true
	canvas_layer.follow_viewport_scale = 1.0
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

func display_hint(heading:String, description:String, position:Vector2):
	pin_popup.visible=true
	pin_popup.display(heading, description, position)

func hide_hint():
	pin_popup.hide_popup()
