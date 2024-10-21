extends Node

static var ic_list: Array[CircuitComponent]

func save(path: String) -> void:
	var json_list_ic: Array
	for ic in ic_list:
		json_list_ic.append(ic.to_json_object())
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(json.stringify({
		"components": json_list_ic,
		"netlist": NetlistClass.get_json_adjacency()
	}, "\t"))
	file.close()

func get_component_by_id(id: int) -> CircuitComponent: #null if not found
	for ic in ic_list:
		if ic.id == id:
			return ic
	return null
func load(scene: Node2D, path: String):
	var json = JSON.new()
	var file = FileAccess.open(path, FileAccess.READ).get_as_text()
	var parsed = json.parse_string(file)
	if parsed == null:
		print("error")
		return
	for ic in parsed.components:
		var component: CircuitComponent
		match(ic.name):
			"К1533ИД4":
				component = K1533ID4.new()
			"2И":
				component = And2.new()
			"Светодиод":
				component = LED.new()
			"Переключатель":
				component = Switch.new()
			"Буфер с 3-м состоянием":
				component = Tristate.new()
			"Ячейка памяти":
				component = Memory.new()
			"КР132РУ9А":
				component = KR132RU9A.new()
			"1531ИР22":
				component = K1531IR22.new()
				
		var spec = ComponentSpecification.new()
		var pinSpecArray: Array[PinSpecification]
		for pin in ic.pins:
			var pinSpec = PinSpecification.new()
			pinSpec.initialize(pin.index, NetConstants.parse_direction(pin.direction), pin.position, pin.readable_name, pin.description,[])
			pinSpecArray.append(pinSpec)
		spec.initialize(ic.name, ic.num_pins, ic.height, ic.width, ic.texture, pinSpecArray)
		component.initialize(spec)
		component.id = ic.id
		scene.add_child(component)
		var pos = ic.position.split(",")
		var x = float(pos[0].replace("(", ""))
		var y = float(pos[1].replace(")", ""))
		component.position = Vector2(x, y)
		ic_list.append(component)
	for edge in parsed.netlist:
		var from_ic = get_component_by_id(edge.from.ic)
		var from_pin: Pin
		for pin in from_ic.pins:
			if pin.index == edge.from.pin:
				from_pin = pin
		if from_pin == null:
			print("error")
			continue
		var to_ic = get_component_by_id(edge.to.ic)
		var to_pin: Pin
		for pin in to_ic.pins:
			if pin.index == edge.to.pin:
				to_pin = pin
		if to_pin == null:
			print("error")
			continue
		WireManager._create_wire(from_pin, to_pin)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
