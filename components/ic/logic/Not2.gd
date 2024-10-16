extends CircuitComponent

class_name Not2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.



func _process_signal():
	pin(2).state =NetConstants.LEVEL.LEVEL_LOW if pin(1).high else NetConstants.LEVEL.LEVEL_HIGH 
