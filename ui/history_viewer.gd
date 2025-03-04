extends Window

@onready var container = get_node("./VBoxContainer/ScrollContainer/VBoxContainer")
var last_events_amount = 0
@onready var selected_buffer = HistoryBuffer.history
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if self.visible:
		if last_events_amount!=HistoryBuffer.history.size(): # Should update

			clear()
			display_buffer(selected_buffer)
			last_events_amount = HistoryBuffer.history.size()
			
		

func clear():
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _on_close_requested() -> void:
	self.hide()

func display_buffer(buffer):
	
	var i = 1
	for event in buffer:
		var label = Label.new()	
		if event is ComponentCreationEvent:
			label.text = "%d. Создание элемента %s:%d" % [i,event.name, event.id ]
		elif event is ComponentDeletionEvent:
			label.text = "%d. Удаление элемента %s:%d" % [i,event.name, event.id ]
		elif event is ControlPointMoveEvent:
			label.text = "%d. Движение контрольной точки from id=%d:pin=%d to id=%d:pin=%d" % [i,event.from_id, event.from_pin, event.to_id, event.to_pin ]
		elif event is MoveEvent:
			label.text = "%d. Движение элемента id=%d" % [i, event.id ]
		elif event is WireCreationEvent:
			label.text = "%d. Создание провода from id=%d:pin=%d to id=%d:pin=%d" % [i,event.from_id, event.from_index, event.to_id, event.to_index ]
		elif event is WireDeletionEvent:
			label.text = "%d. Удаление провода from id=%d:pin=%d to id=%d:pin=%d" % [i,event.from_id, event.from_index, event.to_id, event.to_index ]
		elif event is BusCreationEvent:
			label.text = "%d. Создание шины id=%d" % [i,event.id ]
		elif event is BusDeletionEvent:
			label.text = "%d. Удаление шины id=%d" % [i,event.id ]
		elif event is LabelTextChangeEvent:
			label.text = "%d. Изменение текста метки id=%d с '%s' на '%s'" % [i,event.id, event.old_content, event.new_content ]
		elif event is NEventsBuffer:
			label.text = "%d. Буфер для %d предыдущих событий" % [i,event.n ]
		else:
			label.text = "%d. Неизвестное событие" % [i]
		i +=1
		label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		#label.
		container.add_child(label)


func _on_tab_bar_tab_changed(tab: int) -> void:
	if tab==0:
		selected_buffer = HistoryBuffer.history
	else:
		selected_buffer = HistoryBuffer.redo_buffer
	clear()
	display_buffer(selected_buffer)
