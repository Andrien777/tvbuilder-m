extends HistoryEvent
class_name NEventsBuffer

var n = 0
var allowed_types = []

func initialize(num, types):
	if num > 0:
		n = num
		allowed_types = types.duplicate(true)
	else:
		InfoManager.write_error("Попытка создать группу событий из отрицательного числа элементов")

func undo():
	for i in range(n):
		if allowed_types.any(func (filter):
			return is_instance_of(HistoryBuffer.history.back(), filter)):
			HistoryBuffer.undo_last_event()
		else:
			InfoManager.write_error("Попытка отменить событие группы другого типа")
			break
			
func redo():
	for i in range(n):
		if allowed_types.any(func (filter):
			return is_instance_of(HistoryBuffer.redo_buffer.back(), filter)):
			HistoryBuffer.redo_last_event()
		else:
			InfoManager.write_error("Попытка вернуть событие группы другого типа")
			break
