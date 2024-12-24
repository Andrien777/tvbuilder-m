extends HistoryEvent
class_name MoveEvent
var from
var to
var object
func initialize(from, object):
	self.from = from
	self.to = to
	self.object = object
func undo():
	if is_instance_valid(object):
		object.global_position = self.from
		WireManager.force_update_wires() # TODO: this does not work :( Probably needs a timer
		# I don`t feel like creating a billion timer instances for each event right now
	
