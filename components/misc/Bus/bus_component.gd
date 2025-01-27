extends CircuitComponent
class_name BusComponent
var bus:Bus
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func pin(index:int):
	for pin in bus.connection_pins:
		if pin.index == index:
			return pin
	# If we get asked about pin which does not exist, it is probably the event manager
	# Something wants to connect to the pin, which was no longer needed
	# So we restore that pin
	# Yes, this is a very bad overload for a getter function
	
	for i in range(bus.deleted_pins.size()-1,-1, -1):
		var p = bus.deleted_pins[i]
		if p[1] == index: # [1] is the pin index
			bus.deleted_pins.pop_at(i)
			return bus.add_connection(p[0], p[1], p[2]) # Name, index, position

	return null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func delete_connection(pin):
	bus.delete_connection(pin)

func to_json_object() -> Dictionary:
	return {
		"id": id,
		"name": readable_name,
		"position": position,
		"control_points": bus.control_points,
		"connections":jsonify_connections()
	}
func jsonify_connections():
	var connections = []
	for name in bus.connections:
		var pins = []
		for pin in bus.connections[name]:
			pins.append({
				"index":pin.index,
				"position":pin.position
			})
		connections.append({
			"name":name,
			"pins":pins
		})
	return connections

func fully_delete():
	bus.fully_delete()

func delete_self():
	bus.delete_self()
