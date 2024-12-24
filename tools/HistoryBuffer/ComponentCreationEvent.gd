extends HistoryEvent
class_name ComponentCreationEvent
var object

var name
var position
var connections: Dictionary # Array of Int (pin index), Pin pairs

func initialize(object):
	self.object = object
	
	self.name=  object.readable_name
	self.position = object.get_global_position()
	# TODO: implement restoring wires
	# This will require to populate the connections dict with Int -> Object pairs (self pin index -> other Pin object)
	# The issue is, we don`t know what is connected to a Pin now - only the WireManager knows that
	# Implementing this will mean implementing this functionality in WireManager class
	for wire in WireManager.wires: # Or we could just write some questionable code like this
		if wire.first_object in object.pins:
			connections[wire.first_object.index] = wire.second_object
		elif wire.second_object in object.pins:
			connections[wire.second_object.index] = wire.first_object
	
func undo():
	if is_instance_valid(object):
		ComponentManager.remove_object(object)
		object.queue_free()

func redo():
	if name == null: return
	var spec = ComponentSpecification.new()
	spec.initialize_from_json( ICsTreeManager.get_config_path(name) )
	var element: CircuitComponent = load( ICsTreeManager.get_class_path(name) ).new()
	element.initialize(spec)
	element.position = position
	self.object = element
	ComponentManager.get_node("/root/RootNode").add_child(element) # TODO: idk thats stupid
	#ComponentManager.add_child(element)  # Thats even more stupid though
	for key in connections:
		WireManager._create_wire(element.pin(key), connections[key])
