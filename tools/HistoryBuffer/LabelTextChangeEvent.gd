extends HistoryEvent
class_name LabelTextChangeEvent
var id
var old_content
var new_content

func initialize(object, new_content):
	if object is TextLabel:
		self.new_content = new_content
		self.old_content = object.label.text
		self.id = object.id
	else:
		InfoManager.write_error("Не удалось создать событие изменения текста метки: Был предоставлен объект, не являющийся меткой")

func undo():
	var object =ComponentManager.get_by_id(id)
	if is_instance_valid(object):
		object.label.text = old_content
	else:
		InfoManager.write_error("Не удалось отменить изменение текста метки id = %d" % [self.id])

func redo():
	var object =ComponentManager.get_by_id(id)
	if is_instance_valid(object):
		object.label.text = new_content
	else:
		InfoManager.write_error("Не удалось отменить изменение текста метки id = %d" % [self.id])
