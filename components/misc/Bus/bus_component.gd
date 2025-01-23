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
