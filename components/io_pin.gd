extends Pin

class_name IO_Pin

var current_direction = NetConstants.DIRECTION.DIRECTION_OUTPUT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# TODO: Refactor this to use fields
#var input:
	#get: 	return self.current_direction == NetConstants.DIRECTION.DIRECTION_INPUT
#var output:
	#get: 	return self.current_direction == NetConstants.DIRECTION.DIRECTION_OUTPUT

	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func output(): # TODO: Make member field
	return self.current_direction == NetConstants.DIRECTION.DIRECTION_OUTPUT
func input():
	return self.current_direction == NetConstants.DIRECTION.DIRECTION_INPUT
func set_input():
	self.current_direction = NetConstants.DIRECTION.DIRECTION_INPUT
func set_output():
	self.current_direction = NetConstants.DIRECTION.DIRECTION_OUTPUT
	if GlobalSettings.highlightOutputPins:
		self.modulate = Color(1, 0, 0)
