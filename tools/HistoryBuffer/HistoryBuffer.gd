extends Node

#class_name HistoryBuffer

var history: Array[HistoryEvent] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func register_event(event:HistoryEvent):
	history.append(event) # TODO: Limit history size

func undo_last_event():
	if not history.is_empty():
		var event = history.pop_back()
		event.undo()
		
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
