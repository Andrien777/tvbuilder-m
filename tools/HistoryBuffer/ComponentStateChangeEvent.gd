extends HistoryEvent
class_name ComponentStateChangeEvent

var id
var name = ""
var old_state: Dictionary = {}
var new_state: Dictionary = {}

func initialize(object, previous_state: Dictionary, next_state: Dictionary):
	if not is_instance_valid(object):
		InfoManager.write_error("Не удалось создать событие изменения состояния компонента")
		return
	self.id = object.id
	self.name = object.readable_name
	self.old_state = previous_state.duplicate(true)
	self.new_state = next_state.duplicate(true)

func _apply_state(state: Dictionary):
	var object = ComponentManager.get_by_id(id)
	if not is_instance_valid(object):
		InfoManager.write_error("Ошибка изменения состояния компонента для id=%d" % [id])
		return
	if not object.has_method("apply_history_state"):
		InfoManager.write_error("Компонент %s:%d не поддерживает восстановление состояния" % [name, id])
		return
	object.apply_history_state(state.duplicate(true))

func undo():
	_apply_state(old_state)

func redo():
	_apply_state(new_state)
