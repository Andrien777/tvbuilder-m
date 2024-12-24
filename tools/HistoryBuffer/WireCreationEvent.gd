extends HistoryEvent
class_name WireCreationEvent
var from
var to
func initialize(object):
	self.from = object.first_object
	self.to = object.second_object

func undo():
	WireManager._delete_wire_by_ends(from, to)
	
func redo():
	WireManager._create_wire(from, to)
