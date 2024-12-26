extends Node

#class_name HistoryBuffer

var history: Array[HistoryEvent] = []
var redo_buffer: Array[HistoryEvent] = []
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func register_event(event:HistoryEvent):
	history.append(event)
	while history.size() > GlobalSettings.historyDepth:
		history.pop_front()
	redo_buffer = []

func undo_last_event():
	if not history.is_empty():
		var event = history.pop_back()
		redo_buffer.append(event)
		event.undo()
		
func redo_last_event():
	if not redo_buffer.is_empty():
		var event = redo_buffer.pop_back()
		history.append(event)
		event.redo()
		
		
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
