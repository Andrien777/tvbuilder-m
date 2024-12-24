extends HistoryEvent
class_name ComponentCreationEvent
var object

func initialize(object):
	self.object = object
	
func undo():
	if is_instance_valid(object):
		ComponentManager.remove_object(object)
		object.queue_free()
