extends Node

class_name CopiedItem

var old_id
var item_name: String
var item_offset: Vector2
var connections_with_old_ids = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func copy(obj: CircuitComponent, mouse_pos: Vector2):
	self.item_name = obj.readable_name
	self.item_offset = obj.position - mouse_pos
	self.old_id = obj.id
	for wire in WireManager.wires:
		if wire.first_object in obj.pins and wire.second_object.parent.is_selected:
			if connections_with_old_ids.has(wire.first_object.index):
				connections_with_old_ids[wire.first_object.index].append({"id": wire.second_object.parent.id,"index": wire.second_object.index})
			else:
				connections_with_old_ids[wire.first_object.index] = [{"id": wire.second_object.parent.id,"index": wire.second_object.index}]
		elif wire.second_object in obj.pins and wire.first_object.parent.is_selected:
			if connections_with_old_ids.has(wire.second_object.index):
				connections_with_old_ids[wire.second_object.index].append({"id": wire.first_object.parent.id,"index": wire.first_object.index})
			else:
				connections_with_old_ids[wire.second_object.index] = [{"id": wire.first_object.parent.id,"index": wire.first_object.index}]

func paste(mouse_pos: Vector2):
	if item_name == null: return
	var spec = ComponentSpecification.new()
	
	
	spec.initialize_from_json( ComponentManager.get_config_path_by_name(item_name) )
	var element: CircuitComponent = load( ComponentManager.get_class_path_by_name(item_name) ).new()
	element.initialize(spec)
	element.position = mouse_pos + item_offset
	ComponentManager.get_node("/root/RootNode").add_child(element)
	var event = ComponentCreationEvent.new()
	event.initialize(element)
	HistoryBuffer.register_event(event)
	return element.id
