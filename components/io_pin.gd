extends Pin

class_name IO_Pin

var current_direction = NetConstants.DIRECTION.DIRECTION_OUTPUT

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


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
