extends HistoryEvent
class_name WireCreationEvent
var object
func initialize(object):
	self.object = object # TODO: Sadly, if we create wire, then delete it, then ctrl+z the deletion, it will not be the same wire object that we created in the first place. Therefore, this events undo() will fail
	# Possible solution would be to store the "from" and "to" points, then linear search the wire object if the stored object is not valid anymore
	# That is a possible change for the WireManager itself
func undo():
	WireManager._delete_wire(object)
	
