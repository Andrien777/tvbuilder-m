extends HistoryEvent
class_name WireDeletionEvent

var from
var to
func initialize(from, to):
	self.from = from
	self.to = to

func undo():
	WireManager._create_wire(from, to)
